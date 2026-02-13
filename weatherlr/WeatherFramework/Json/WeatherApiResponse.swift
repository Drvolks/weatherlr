//
//  WeatherApiResponse.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2026-02-12.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
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

// MARK: - Warnings
struct WarningEntry: Codable {
    let description: Bilingual<String>?
    let url: Bilingual<String>?
    let type: Bilingual<String>?
    let expiryTime: Bilingual<String>?
    let eventIssue: Bilingual<String>?
    let alertColourLevel: Bilingual<String>?
}
