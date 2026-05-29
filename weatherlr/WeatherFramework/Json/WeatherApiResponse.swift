//
//  WeatherApiResponse.swift
//  weatherlr
//
//  Created by drvolks on 2026-02-12.
//  Copyright © 2026 drvolks. All rights reserved.
//

import Foundation

// MARK: - Bilingual value wrapper
struct Bilingual<T: Codable>: Codable {
    let en: T?
    let fr: T?

    func value(for language: Language) -> T? {
        switch language {
        case .English:
            return en
        case .French:
            return fr
        }
    }
}

// MARK: - Top-level response
struct WeatherApiResponse: Codable {
    let type: String?
    let properties: WeatherProperties?
    let id: String?
}

// MARK: - Properties
struct WeatherProperties: Codable {
    let currentConditions: CurrentConditions?
    let forecastGroup: ForecastGroup?
    let hourlyForecastGroup: HourlyForecastGroup?
    let warnings: [WarningEntry]?
}

// MARK: - Current Conditions
struct CurrentConditions: Codable {
    let iconCode: IconCode?
    let timestamp: Bilingual<String>?
    let temperature: CurrentTemperature?
    let condition: Bilingual<String>?
    let windChill: CurrentWindChill?
}

struct CurrentTemperature: Codable {
    let value: Bilingual<Double>?
}

struct CurrentWindChill: Codable {
    let value: Bilingual<Int>?
}

struct IconCode: Codable {
    let format: String?
    let value: Int?
    let url: String?
}

// MARK: - Forecast Group
struct ForecastGroup: Codable {
    let forecasts: [Forecast]?
}

struct Forecast: Codable {
    let period: ForecastPeriod?
    let temperatures: ForecastTemperatures?
    let abbreviatedForecast: AbbreviatedForecast?
    let textSummary: Bilingual<String>?
    let cloudPrecip: Bilingual<String>?
}

struct ForecastPeriod: Codable {
    let textForecastName: Bilingual<String>?
    let value: Bilingual<String>?
}

struct ForecastTemperatures: Codable {
    let temperature: [ForecastTemperatureEntry]?
    let textSummary: Bilingual<String>?
}

struct ForecastTemperatureEntry: Codable {
    let `class`: Bilingual<String>?
    let value: Bilingual<Double>?
}

struct AbbreviatedForecast: Codable {
    let icon: IconCode?
    let textSummary: Bilingual<String>?
}

// MARK: - Hourly Forecast Group
struct HourlyForecastGroup: Codable {
    let hourlyForecasts: [HourlyForecast]?
}

struct HourlyForecast: Codable {
    let condition: Bilingual<String>?
    let temperature: HourlyTemperature?
    let iconCode: IconCode?
    let lop: HourlyLop?
    let timestamp: String?
}

struct HourlyTemperature: Codable {
    let value: Bilingual<Int>?
}

struct HourlyLop: Codable {
    let value: Bilingual<Int>?
}

// MARK: - Warnings
//
// The citypageweather-realtime API exposes only these six keys per warning, and
// `description` is just a short headline (e.g. "YELLOW WARNING - RAINFALL").
// There is no inline body/bulletin field — the full warning text lives only at
// `url`. (Verified against all active warnings across every city, 2026-05.)
// `AlertDetailViewController` therefore loads `url` in a web view to show the
// full bulletin in-app. See issue #20.
struct WarningEntry: Codable {
    let description: Bilingual<String>?
    let url: Bilingual<String>?
    let type: Bilingual<String>?
    let expiryTime: Bilingual<String>?
    let eventIssue: Bilingual<String>?
    let alertColourLevel: Bilingual<String>?
}

// MARK: - Weather Alerts (full bulletin text)
//
// The full warning body that citypageweather omits is served by the separate
// `weather-alerts` collection. A citypageweather warning is joined to it via the
// `#anchor` at the end of `WarningEntry.url`, which matches the leading part of
// a weather-alerts feature `id`. Decoded with `.convertFromSnakeCase`, so the
// JSON keys `alert_text_en` / `alert_text_fr` map to these properties. See #20.
struct WeatherAlertsResponse: Codable {
    let features: [WeatherAlertFeature]?
}

struct WeatherAlertFeature: Codable {
    let properties: WeatherAlertProperties?
}

struct WeatherAlertProperties: Codable {
    let alertTextEn: String?
    let alertTextFr: String?

    func value(for language: Language) -> String? {
        switch language {
        case .English: return alertTextEn
        case .French: return alertTextFr
        }
    }
}
