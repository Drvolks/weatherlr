//
//  watchWidget.swift
//  watch Widget
//
//  Created by Jean-Francois Dufour on 2026-02-17.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import WidgetKit
import SwiftUI
import CoreLocation
#if ENABLE_WEATHERKIT
import WeatherKit
#endif

// MARK: - Models

struct WatchWeatherEntry: TimelineEntry {
    let date: Date
    let cityName: String
    let temperature: Int
    let weatherImageName: String
    let hasPWS: Bool
    let hasData: Bool
    let minTemperature: Int?
    let maxTemperature: Int?
}

// MARK: - Provider

struct WatchWeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchWeatherEntry {
        WatchWeatherEntry(date: Date(), cityName: "---", temperature: 0, weatherImageName: "na", hasPWS: false, hasData: false, minTemperature: nil, maxTemperature: nil)
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

            #if ENABLE_WEATHERKIT
            let wkImageName = Self.fetchWeatherKitImageSync(for: city)
            #else
            let wkImageName: String? = nil
            #endif

            let entry = Self.buildEntry(city: city, wrapper: wrapper, hasPWS: pws.hasPWS, pwsTemp: pws.temperature, pwsStationName: pws.stationName, weatherKitImageName: wkImageName)
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
            completion(timeline)
        }
    }

    #if ENABLE_PWS
    static func fetchPWSSync(for city: City) -> (hasPWS: Bool, temperature: Int?, stationName: String?) {
        let stations = PreferenceHelper.getPWSStations()
        guard !stations.isEmpty,
              PreferenceHelper.hasPWSCredentials(),
              let cityLat = Double(city.latitude),
              let cityLon = Double(city.longitude),
              let apiKey = PreferenceHelper.getPWSApiKey() else {
            return (false, nil, nil)
        }

        let cityLocation = CLLocation(latitude: cityLat, longitude: cityLon)

        for station in stations {
            let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
            let distance = cityLocation.distance(from: stationLocation)
            guard distance < 50_000 else { continue }

            let urlString = "https://api.weather.com/v2/pws/observations/current?stationId=\(station.stationId)&format=json&units=e&apiKey=\(apiKey)"
            guard let url = URL(string: urlString) else { continue }

            guard let data = try? Data(contentsOf: url),
                  let response = try? JSONDecoder().decode(WUResponse.self, from: data),
                  let observation = response.observations?.first,
                  let tempC = observation.tempC else { continue }

            return (true, Int(tempC.rounded()), station.name)
        }

        return (false, nil, nil)
    }
    #endif

    static func fetchWeatherSync(for city: City) -> WeatherInformationWrapper {
        guard let url = URL(string: UrlHelper.getUrl(city)) else {
            return WeatherInformationWrapper()
        }

        guard let data = try? Data(contentsOf: url) else {
            return WeatherInformationWrapper()
        }

        return WeatherHelper.getWeatherInformationsNoCache(data, city: city)
    }

    #if ENABLE_WEATHERKIT
    private final class WeatherKitImageBox: @unchecked Sendable {
        var imageName: String?
    }

    static func fetchWeatherKitImageSync(for city: City) -> String? {
        guard let lat = Double(city.latitude), let lon = Double(city.longitude) else {
            return nil
        }

        let location = CLLocation(latitude: lat, longitude: lon)
        let semaphore = DispatchSemaphore(value: 0)
        let box = WeatherKitImageBox()

        Task.detached {
            defer { semaphore.signal() }
            do {
                let weather = try await WeatherService.shared.weather(for: location, including: .current)
                let condition = weather.condition
                let night = !weather.isDaylight

                box.imageName = WeatherHelper.imageName(for: condition, night: night)
            } catch {
                #if DEBUG
                print("WeatherKit watch widget error: \(error)")
                #endif
            }
        }

        semaphore.wait()
        return box.imageName
    }
    #endif

    private func buildEntry() -> WatchWeatherEntry {
        let city = PreferenceHelper.getCityToUse()
        let wrapper = Self.fetchWeatherSync(for: city)
        return Self.buildEntry(city: city, wrapper: wrapper, hasPWS: false, pwsTemp: nil, pwsStationName: nil, weatherKitImageName: nil)
    }

    static func buildEntry(city: City, wrapper: WeatherInformationWrapper, hasPWS: Bool, pwsTemp: Int?, pwsStationName: String?, weatherKitImageName: String?) -> WatchWeatherEntry {
        let cityName = (hasPWS ? pwsStationName : nil) ?? CityHelper.cityName(city)

        guard wrapper.weatherInformations.count > 0 else {
            return WatchWeatherEntry(date: Date(), cityName: cityName, temperature: 0, weatherImageName: "na", hasPWS: false, hasData: false, minTemperature: nil, maxTemperature: nil)
        }

        let current = wrapper.weatherInformations[0]
        let temperature = pwsTemp ?? current.temperature

        let imageName: String
        if let wkName = weatherKitImageName {
            imageName = wkName
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

        return WatchWeatherEntry(
            date: Date(),
            cityName: cityName,
            temperature: temperature,
            weatherImageName: imageName,
            hasPWS: hasPWS,
            hasData: true,
            minTemperature: minTemp,
            maxTemperature: maxTemp
        )
    }
}

// MARK: - Views

struct WatchAccessoryRectangularView: View {
    let entry: WatchWeatherEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(entry.weatherImageName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(entry.temperature)\u{00B0}")
                    .font(.system(size: 20, weight: .medium))
                HStack(spacing: 2) {
                    Text(entry.cityName)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    #if ENABLE_PWS
                    if entry.hasPWS {
                        Image(systemName: "sensor.fill")
                            .font(.system(size: 8))
                    }
                    #endif
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
            WatchWeatherWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 31.0/255.0, green: 79.0/255.0, blue: 116.0/255.0), for: .widget)
        }
        .configurationDisplayName("PréviCA")
        .description("Current weather conditions")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}
