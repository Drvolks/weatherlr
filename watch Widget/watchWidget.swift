//
//  watchWidget.swift
//  watch Widget
//
//  Created by drvolks on 2026-02-17.
//  Copyright © 2026 drvolks. All rights reserved.
//

import WidgetKit
import SwiftUI
import CoreLocation

// MARK: - Models

struct WatchHourlyItem {
    let hour: String
    let imageName: String
    let temperature: Int
}

struct WatchWeatherEntry: TimelineEntry {
    let date: Date
    let cityName: String
    let temperature: Int
    let weatherImageName: String
    let hasPWS: Bool
    let hasData: Bool
    let minTemperature: Int?
    let maxTemperature: Int?
    let hourlyItems: [WatchHourlyItem]
}

// MARK: - Provider

struct WatchWeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchWeatherEntry {
        WatchWeatherEntry(date: Date(), cityName: "---", temperature: 0, weatherImageName: "na", hasPWS: false, hasData: false, minTemperature: nil, maxTemperature: nil, hourlyItems: [])
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (WatchWeatherEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                completion(self.buildEntry())
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<WatchWeatherEntry>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let city = PreferenceHelper.getCityToUse()
            let wrapper = Self.fetchWeatherSync(for: city)

            #if ENABLE_PWS
            let pws = Self.fetchPWSSync(for: city)
            #else
            let pws = (hasPWS: false, temperature: nil as Int?, stationName: nil as String?)
            #endif

            let entry = Self.buildEntry(city: city, wrapper: wrapper, hasPWS: pws.hasPWS, pwsTemp: pws.temperature, pwsStationName: pws.stationName)
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
            completion(timeline)
        }
    }

    #if ENABLE_PWS
    static func fetchPWSSync(for city: City) -> (hasPWS: Bool, temperature: Int?, stationName: String?) {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        let stationName = defaults.string(forKey: Global.pwsStationNameKey)
        guard stationName != nil, defaults.object(forKey: Global.pwsTemperatureKey) != nil else {
            return (false, nil, nil)
        }

        // Verify the synced station is within range of the current city
        let stations = PreferenceHelper.getPWSStations()
        guard !stations.isEmpty,
              let cityLat = Double(city.latitude),
              let cityLon = Double(city.longitude) else {
            return (false, nil, nil)
        }

        let cityLocation = CLLocation(latitude: cityLat, longitude: cityLon)
        let hasNearbyStation = stations.contains { station in
            let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
            return cityLocation.distance(from: stationLocation) < 50_000
        }

        guard hasNearbyStation else { return (false, nil, nil) }

        let temperature = defaults.integer(forKey: Global.pwsTemperatureKey)
        return (true, temperature, stationName)
    }
    #endif

    static func fetchWeatherSync(for city: City) -> WeatherInformationWrapper {
        guard let url = URL(string: UrlHelper.getUrl(city)) else {
            return WeatherInformationWrapper()
        }

        let semaphore = DispatchSemaphore(value: 0)
        var fetchedData: Data?

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 15
        let session = URLSession(configuration: config)

        let task = session.dataTask(with: url) { data, _, _ in
            fetchedData = data
            semaphore.signal()
        }
        task.resume()

        let timeout = semaphore.wait(timeout: .now() + 15)
        if timeout == .timedOut {
            task.cancel()
            #if DEBUG
            print("EC weather fetch timed out for watch widget")
            #endif
            return WeatherInformationWrapper()
        }

        guard let data = fetchedData else {
            return WeatherInformationWrapper()
        }

        return WeatherHelper.getWeatherInformationsNoCache(data, city: city)
    }

    private func buildEntry() -> WatchWeatherEntry {
        let city = PreferenceHelper.getCityToUse()
        let wrapper = Self.fetchWeatherSync(for: city)
        return Self.buildEntry(city: city, wrapper: wrapper, hasPWS: false, pwsTemp: nil, pwsStationName: nil)
    }

    static func buildEntry(city: City, wrapper: WeatherInformationWrapper, hasPWS: Bool, pwsTemp: Int?, pwsStationName: String?) -> WatchWeatherEntry {
        let cityName = (hasPWS ? pwsStationName : nil) ?? CityHelper.cityName(city)

        guard wrapper.weatherInformations.count > 0 else {
            return WatchWeatherEntry(date: Date(), cityName: cityName, temperature: 0, weatherImageName: "na", hasPWS: false, hasData: false, minTemperature: nil, maxTemperature: nil, hourlyItems: [])
        }

        let current = wrapper.weatherInformations[0]
        let temperature = pwsTemp ?? current.temperature

        let imageName: String
        if let code = current.iconCode, let name = WeatherHelper.imageNameForIconCode(code) {
            imageName = name
        } else {
            var status = current.weatherStatus
            if let substitute = WeatherHelper.getImageSubstitute(status) {
                status = substitute
            }
            if current.night, let nightName = WeatherHelper.getNightImageName(status) {
                imageName = nightName
            } else {
                imageName = String(describing: status)
            }
        }

        // Extract min/max from forecast entries
        var minTemp: Int? = nil
        var maxTemp: Int? = nil
        for info in wrapper.weatherInformations {
            if info.weatherDay == .today || info.weatherDay == .tomorow {
                if info.tendancy == .minimum {
                    minTemp = info.temperature
                } else if info.tendancy == .maximum {
                    maxTemp = info.temperature
                }
            }
        }
        // If we only have one bound, estimate the other from current temperature
        if minTemp == nil && maxTemp != nil {
            minTemp = min(temperature, maxTemp!) - 5
        }
        if maxTemp == nil && minTemp != nil {
            maxTemp = max(temperature, minTemp!) + 5
        }

        // Build hourly items from EC data
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        let hourlyItems: [WatchHourlyItem] = wrapper.hourlyForecasts.prefix(5).map { hourly in
            let hour = formatter.string(from: hourly.date) + "h"
            return WatchHourlyItem(hour: hour, imageName: hourly.imageName, temperature: hourly.temperature)
        }

        return WatchWeatherEntry(
            date: Date(),
            cityName: cityName,
            temperature: temperature,
            weatherImageName: imageName,
            hasPWS: hasPWS,
            hasData: true,
            minTemperature: minTemp,
            maxTemperature: maxTemp,
            hourlyItems: hourlyItems
        )
    }
}

// MARK: - Views

struct WatchAccessoryRectangularView: View {
    let entry: WatchWeatherEntry

    var body: some View {
        VStack(spacing: 2) {
            // Line 1: icon, temperature, city
            HStack(spacing: 4) {
                Image(entry.weatherImageName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text("\(entry.temperature)\u{00B0}")
                    .font(.system(size: 16, weight: .medium))
                Text(entry.cityName)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                #if ENABLE_PWS
                if entry.hasPWS {
                    Image(systemName: "sensor.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                #endif
            }

            // Line 2: hourly forecasts
            if !entry.hourlyItems.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(entry.hourlyItems.enumerated()), id: \.offset) { _, item in
                        VStack(spacing: 1) {
                            Text(item.hour)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Image(item.imageName)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                            Text("\(item.temperature)\u{00B0}")
                                .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

struct WatchAccessoryCircularView: View {
    let entry: WatchWeatherEntry

    var body: some View {
        if let minTemp = entry.minTemperature, let maxTemp = entry.maxTemperature, maxTemp > minTemp {
            let clampedTemp = min(max(Double(entry.temperature), Double(minTemp)), Double(maxTemp))
            Gauge(value: clampedTemp, in: Double(minTemp)...Double(maxTemp)) {
                Text("")
            } currentValueLabel: {
                Text("\(entry.temperature)\u{00B0}")
                    .font(.system(size: 18, weight: .medium))
            } minimumValueLabel: {
                Text("\(minTemp)")
                    .font(.system(size: 9))
            } maximumValueLabel: {
                Text("\(maxTemp)")
                    .font(.system(size: 9))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [.blue, .green, .yellow, .orange, .red]))
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Text("\(entry.temperature)\u{00B0}")
                    .font(.system(size: 22, weight: .medium))
            }
        }
    }
}

struct WatchAccessoryInlineView: View {
    let entry: WatchWeatherEntry

    var body: some View {
        Text("\(entry.cityName) \(entry.temperature)\u{00B0}")
    }
}

struct WatchAccessoryCornerView: View {
    let entry: WatchWeatherEntry

    var body: some View {
        if let minTemp = entry.minTemperature, let maxTemp = entry.maxTemperature, maxTemp > minTemp {
            let clampedTemp = min(max(Double(entry.temperature), Double(minTemp)), Double(maxTemp))
            Text("\(entry.temperature)\u{00B0}")
                .font(.system(size: 28, weight: .medium))
                .widgetLabel {
                    Gauge(value: clampedTemp, in: Double(minTemp)...Double(maxTemp)) {
                        Text(entry.cityName)
                    } currentValueLabel: {
                        Text("\(entry.temperature)\u{00B0}")
                    } minimumValueLabel: {
                        Text("\(minTemp)\u{00B0}")
                    } maximumValueLabel: {
                        Text("\(maxTemp)\u{00B0}")
                    }
                    .tint(Gradient(colors: [.blue, .green, .yellow, .orange, .red]))
                }
        } else {
            Text("\(entry.temperature)\u{00B0}")
                .font(.system(size: 28, weight: .medium))
                .widgetLabel {
                    Text(entry.cityName)
                }
        }
    }
}

struct WatchWeatherWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WatchWeatherEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            WatchAccessoryCircularView(entry: entry)
        case .accessoryInline:
            WatchAccessoryInlineView(entry: entry)
        case .accessoryCorner:
            WatchAccessoryCornerView(entry: entry)
        default:
            WatchAccessoryRectangularView(entry: entry)
        }
    }
}

// MARK: - Widget

@main
struct WatchWeatherWidget: Widget {
    let kind = "WatchWeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchWeatherTimelineProvider()) { entry in
            if #available(watchOSApplicationExtension 10.0, *) {
                WatchWeatherWidgetEntryView(entry: entry)
                    .containerBackground(Color(red: 31.0/255.0, green: 79.0/255.0, blue: 116.0/255.0), for: .widget)
            } else {
                WatchWeatherWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("PréviCA")
        .description("Current weather conditions")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}
