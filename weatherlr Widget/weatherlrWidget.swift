//
//  weatherlrWidget.swift
//  weatherlr Widget
//
//  Created by Jean-Francois Dufour on 2026-02-13.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import WidgetKit
import SwiftUI
import CoreLocation
#if ENABLE_WEATHERKIT
import WeatherKit
#endif

// MARK: - Models

struct WeatherEntry: TimelineEntry {
    let date: Date
    let cityName: String
    let temperature: Int
    let weatherImageName: String
    let hasPWS: Bool
    let forecasts: [ForecastItem]
    let longTermForecast: ForecastItem?
    let precipitationIntensities: [Double]
    let hasData: Bool
}

struct ForecastItem {
    let label: String
    let imageName: String
    let temperatureText: String
}

// MARK: - Provider

struct WeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), cityName: "---", temperature: 0, weatherImageName: "na", hasPWS: false, forecasts: [], longTermForecast: nil, precipitationIntensities: [], hasData: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            completion(buildEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let city = PreferenceHelper.getCityToUse()
        let wrapper = WeatherHelper.getWeatherInformationsNoCache(city)

        #if ENABLE_PWS
        let pws = Self.fetchPWSSync(for: city)
        #else
        let pws = (hasPWS: false, temperature: nil as Int?, stationName: nil as String?)
        #endif
        #if ENABLE_WEATHERKIT
        let wk = Self.fetchWeatherKitSync(for: city)
        #else
        let wk = (hourly: [ForecastItem](), precipitation: [Double](), currentImageName: nil as String?)
        #endif

        let entry = Self.buildEntry(city: city, wrapper: wrapper, hasPWS: pws.hasPWS, pwsTemp: pws.temperature, pwsStationName: pws.stationName, hourlyForecasts: wk.hourly, precipitationIntensities: wk.precipitation, currentImageName: wk.currentImageName)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
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
            guard let url = URL(string: urlString),
                  let data = try? Data(contentsOf: url),
                  let response = try? JSONDecoder().decode(WUResponse.self, from: data),
                  let observation = response.observations?.first,
                  let tempC = observation.tempC else { continue }

            return (true, Int(tempC.rounded()), station.name)
        }

        return (false, nil, nil)
    }
    #endif

    #if ENABLE_WEATHERKIT
    private final class WeatherKitResultBox: @unchecked Sendable {
        var currentImageName: String?
        var hourlyForecasts: [ForecastItem] = []
        var precipitationIntensities: [Double] = []
    }

    static func fetchWeatherKitSync(for city: City) -> (hourly: [ForecastItem], precipitation: [Double], currentImageName: String?) {
        guard let lat = Double(city.latitude), let lon = Double(city.longitude) else {
            return ([], [], nil)
        }

        let location = CLLocation(latitude: lat, longitude: lon)
        let semaphore = DispatchSemaphore(value: 0)
        let box = WeatherKitResultBox()

        Task.detached {
            defer { semaphore.signal() }
            do {
                let weather = try await WeatherService.shared.weather(for: location, including: .current, .minute, .hourly)
                let currentWeather = weather.0
                let minuteForecast = weather.1
                let hourlyForecast = weather.2

                // Current condition
                box.currentImageName = weatherImageNameForCondition(currentWeather.condition, night: !currentWeather.isDaylight)

                // Hourly
                let now = Date()
                let hours = Array(hourlyForecast.filter { $0.date >= now }.prefix(5))
                let formatter = DateFormatter()
                formatter.dateFormat = "HH"

                for hour in hours {
                    let label = formatter.string(from: hour.date) + "h"
                    let imageName = weatherImageNameForCondition(hour.condition, night: !hour.isDaylight)
                    let temp = Int(hour.temperature.value.rounded())
                    box.hourlyForecasts.append(ForecastItem(
                        label: label,
                        imageName: imageName,
                        temperatureText: "\(temp)°"
                    ))
                }

                // Minute precipitation
                if let minutes = minuteForecast {
                    let hasAnyPrecip = minutes.contains { $0.precipitationChance > 0 }
                    if hasAnyPrecip {
                        box.precipitationIntensities = minutes.map { $0.precipitationIntensity.value }
                    }
                }
            } catch {
                #if DEBUG
                print("WeatherKit widget error: \(error)")
                #endif
            }
        }

        semaphore.wait()
        return (box.hourlyForecasts, box.precipitationIntensities, box.currentImageName)
    }

    static func weatherImageNameForCondition(_ condition: WeatherCondition, night: Bool) -> String {
        var status = WeatherHelper.weatherStatus(from: condition)
        if let substitute = WeatherHelper.getImageSubstitute(status) {
            status = substitute
        }

        if night, let nightName = WeatherHelper.getNightImageName(status) {
            return nightName
        }

        return String(describing: status)
    }
    #endif

    private func buildEntry() -> WeatherEntry {
        let city = PreferenceHelper.getCityToUse()
        let wrapper = WeatherHelper.getWeatherInformationsNoCache(city)
        return Self.buildEntry(city: city, wrapper: wrapper, hasPWS: false, pwsTemp: nil, pwsStationName: nil, hourlyForecasts: [], precipitationIntensities: [], currentImageName: nil)
    }

    static func buildEntry(city: City, wrapper: WeatherInformationWrapper, hasPWS: Bool, pwsTemp: Int?, pwsStationName: String?, hourlyForecasts: [ForecastItem], precipitationIntensities: [Double], currentImageName: String?) -> WeatherEntry {
        let cityName = (hasPWS ? pwsStationName : nil) ?? CityHelper.cityName(city)

        guard wrapper.weatherInformations.count > 0 else {
            return WeatherEntry(date: Date(), cityName: cityName, temperature: 0, weatherImageName: "na", hasPWS: false, forecasts: [], longTermForecast: nil, precipitationIntensities: [], hasData: false)
        }

        let current = wrapper.weatherInformations[0]
        let temperature = pwsTemp ?? current.temperature
        let imageName = currentImageName ?? weatherImageName(for: current)

        let indexAdjust = WeatherHelper.getIndexAjust(wrapper.weatherInformations)

        // Use WeatherKit hourly data; fall back to EC forecasts if unavailable
        var forecasts: [ForecastItem]
        if !hourlyForecasts.isEmpty {
            forecasts = hourlyForecasts
        } else {
            forecasts = [ForecastItem]()
            let startIndex = indexAdjust
            let endIndex = min(startIndex + 4, wrapper.weatherInformations.count)

            for i in startIndex..<endIndex {
                let info = wrapper.weatherInformations[i]
                forecasts.append(ForecastItem(
                    label: info.when,
                    imageName: weatherImageName(for: info),
                    temperatureText: WeatherHelper.getWeatherTextWithMinMax(info)
                ))
            }
        }

        // Long-term EC forecast (skip "today", take the next period)
        var longTermForecast: ForecastItem? = nil
        if indexAdjust + 1 < wrapper.weatherInformations.count {
            let info = wrapper.weatherInformations[indexAdjust + 1]
            longTermForecast = ForecastItem(
                label: info.when,
                imageName: weatherImageName(for: info),
                temperatureText: WeatherHelper.getWeatherTextWithMinMax(info)
            )
        }

        return WeatherEntry(
            date: Date(),
            cityName: cityName,
            temperature: temperature,
            weatherImageName: imageName,
            hasPWS: hasPWS,
            forecasts: forecasts,
            longTermForecast: longTermForecast,
            precipitationIntensities: precipitationIntensities,
            hasData: true
        )
    }

    static func weatherImageName(for info: WeatherInformation) -> String {
        var status = info.weatherStatus
        if let substitute = WeatherHelper.getImageSubstitute(status) {
            status = substitute
        }

        if info.night, let nightName = WeatherHelper.getNightImageName(status) {
            return nightName
        }

        return String(describing: status)
    }
}

// MARK: - Views

private let widgetBackground = Color(red: 31.0/255.0, green: 79.0/255.0, blue: 116.0/255.0)

struct SmallWeatherView: View {
    let entry: WeatherEntry

    var body: some View {
        VStack(spacing: 2) {
            Image(entry.weatherImageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
            Text("\(entry.temperature)\u{00B0}")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white)
            HStack(spacing: 4) {
                Text(entry.cityName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                #if ENABLE_PWS
                if entry.hasPWS {
                    Image(systemName: "sensor.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                #endif
            }
        }
    }
}

#if ENABLE_WEATHERKIT
struct PrecipitationChart: View {
    let intensities: [Double]
    private let barColor = Color(red: 0.4, green: 0.7, blue: 1.0)

    private var scaleMax: Double {
        let dataMax = intensities.prefix(60).max() ?? 0
        return max(dataMax * 3.0, 0.3)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("Precipitation next hour".localized())
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)

            GeometryReader { geometry in
                // Horizontal guide lines
                Path { path in
                    for fraction in [1.0 / 3.0, 2.0 / 3.0, 1.0] {
                        let y = geometry.size.height * (1.0 - CGFloat(fraction))
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                .foregroundStyle(.white.opacity(0.15))

                HStack(alignment: .bottom, spacing: 1) {
                    ForEach(0..<min(intensities.count, 60), id: \.self) { i in
                        let normalized = min(intensities[i] / scaleMax, 1.0)
                        Rectangle()
                            .fill(barColor.opacity(0.9))
                            .frame(height: max(CGFloat(normalized) * geometry.size.height, normalized > 0 ? 2 : 0))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }

            HStack {
                Text("Now".localized())
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("30m")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("60m")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}
#endif

struct MediumWeatherView: View {
    let entry: WeatherEntry

    #if ENABLE_WEATHERKIT
    private var hasPrecipitation: Bool {
        !entry.precipitationIntensities.isEmpty
    }
    #else
    private var hasPrecipitation: Bool {
        false
    }
    #endif

    var body: some View {
        if hasPrecipitation {
            precipitationLayout
        } else {
            forecastLayout
        }
    }

    #if ENABLE_WEATHERKIT
    private var precipitationLayout: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text(entry.cityName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                #if ENABLE_PWS
                if entry.hasPWS {
                    Image(systemName: "sensor.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                #endif
                Spacer()
                Image(entry.weatherImageName)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                Text("\(entry.temperature)\u{00B0}")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white)
            }

            PrecipitationChart(intensities: entry.precipitationIntensities)
        }
    }
    #else
    private var precipitationLayout: some View {
        EmptyView()
    }
    #endif

    private var forecastLayout: some View {
        HStack(spacing: 0) {
            // Left: Current weather
            VStack(spacing: 4) {
                Image(entry.weatherImageName)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                Text("\(entry.temperature)\u{00B0}")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    Text(entry.cityName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                    #if ENABLE_PWS
                    if entry.hasPWS {
                        Image(systemName: "sensor.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    #endif
                }
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 8)

            // Right: Hourly forecast + long-term forecast
            VStack(spacing: 3) {
                ForEach(Array(entry.forecasts.enumerated()), id: \.offset) { _, forecast in
                    HStack(spacing: 4) {
                        Text(forecast.label)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                            .frame(width: 32, alignment: .trailing)
                        Image(forecast.imageName)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                        Text(forecast.temperatureText)
                            .font(.system(size: 11))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .frame(width: 28, alignment: .trailing)
                    }
                }

                if let longTerm = entry.longTermForecast {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 8)

                    HStack(spacing: 4) {
                        Text(longTerm.label)
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Image(longTerm.imageName)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                        Text(longTerm.temperatureText)
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct AccessoryCircularView: View {
    let entry: WeatherEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(entry.temperature)\u{00B0}")
                    .font(.system(size: 22, weight: .medium))
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

struct WeatherlrWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WeatherEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWeatherView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        default:
            SmallWeatherView(entry: entry)
        }
    }
}

// MARK: - Widget

@main
struct WeatherlrWidget: Widget {
    let kind = "WeatherlrWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            WeatherlrWidgetEntryView(entry: entry)
                .containerBackground(widgetBackground, for: .widget)
        }
        .configurationDisplayName("PréviCA")
        .description("Current weather conditions")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}
