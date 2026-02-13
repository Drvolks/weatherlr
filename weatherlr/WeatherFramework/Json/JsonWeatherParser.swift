//
//  JsonWeatherParser.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2026-02-12.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import Foundation

public class JsonWeatherParser {
    let data: Data
    let language: Language
    let weatherStatusConverter = RssEntryToWeatherInformation(rssEntries: [RssEntry]())

    public init(data: Data, language: Language) {
        self.data = data
        self.language = language
    }

    public func parse() -> ([WeatherInformation], [AlertInformation]) {
        guard let response = try? JSONDecoder().decode(WeatherApiResponse.self, from: data) else {
            return ([], [])
        }

        let weatherInformations = buildWeatherInformations(response)
        let alerts = buildAlerts(response)

        return (weatherInformations, alerts)
    }

    // MARK: - Weather Informations

    func buildWeatherInformations(_ response: WeatherApiResponse) -> [WeatherInformation] {
        var result = [WeatherInformation]()
        var day = 0

        // Current conditions → .now entry
        if let cc = response.properties?.currentConditions,
           let tempValue = cc.temperature?.value?.value(for: language) {

            let temperature = Int(round(tempValue))

            let weatherStatus: WeatherStatus
            if let conditionText = cc.condition?.value(for: language), !conditionText.isEmpty {
                weatherStatus = weatherStatusConverter.convertWeatherStatus(conditionText)
            } else if let firstForecast = response.properties?.forecastGroup?.forecasts?.first,
                      let fallbackText = firstForecast.abbreviatedForecast?.textSummary?.value(for: language), !fallbackText.isEmpty {
                weatherStatus = weatherStatusConverter.convertWeatherStatus(fallbackText)
            } else {
                weatherStatus = .blank
            }

            let dateObservation = formatObservationDate(cc.timestamp?.value(for: language))

            let now = WeatherInformation(
                temperature: temperature,
                weatherStatus: weatherStatus,
                weatherDay: .now,
                summary: "",
                detail: "",
                tendancy: .na,
                when: "",
                night: false,
                dateObservation: dateObservation
            )
            result.append(now)
        }

        // Forecasts
        guard let forecasts = response.properties?.forecastGroup?.forecasts, !forecasts.isEmpty else {
            return result
        }

        // The API duplicates forecasts (first half = second half). Use only the first half.
        let forecastCount = forecasts.count / 2
        let uniqueForecasts = Array(forecasts.prefix(forecastCount > 0 ? forecastCount : forecasts.count))

        for forecast in uniqueForecasts {
            let periodName = forecast.period?.textForecastName?.value(for: language) ?? ""
            let night = isNight(periodName)

            guard let weatherDay = WeatherDay(rawValue: day) else { continue }

            let temperature: Int
            if let tempEntry = forecast.temperatures?.temperature?.first,
               let tempValue = tempEntry.value?.value(for: language) {
                temperature = Int(round(tempValue))
            } else {
                temperature = 0
            }

            let conditionText = forecast.abbreviatedForecast?.textSummary?.value(for: language) ?? ""
            let weatherStatus = weatherStatusConverter.convertWeatherStatus(conditionText)

            let tendency = extractTendency(forecast)
            let detail = forecast.textSummary?.value(for: language) ?? ""
            let when = periodName

            let weatherInfo = WeatherInformation(
                temperature: temperature,
                weatherStatus: weatherStatus,
                weatherDay: weatherDay,
                summary: detail,
                detail: detail,
                tendancy: tendency,
                when: when,
                night: night,
                dateObservation: ""
            )

            // If today's night forecast follows a .now entry, mark .now as night too
            if weatherDay == .today && night {
                if result.count > 0 && result[result.count - 1].weatherDay == .now {
                    result[result.count - 1].night = true
                }
            }

            result.append(weatherInfo)

            // Increment day counter (same logic as RSS parser)
            if weatherDay != .now && (!night || weatherDay == .today) {
                day += 1
            }
        }

        return result
    }

    // MARK: - Alerts

    func buildAlerts(_ response: WeatherApiResponse) -> [AlertInformation] {
        guard let warnings = response.properties?.warnings else {
            return []
        }

        var result = [AlertInformation]()

        for warning in warnings {
            let alertText = warning.description?.value(for: language) ?? ""
            if alertText.isEmpty { continue }

            let url = warning.url?.value(for: language) ?? ""
            let alertType = extractAlertType(alertText)

            if alertType != .none && alertType != .ended {
                let eventIssueTime = warning.eventIssue?.value(for: language) ?? ""
                let expiryTime = warning.expiryTime?.value(for: language) ?? ""
                let alertColourLevel = warning.alertColourLevel?.value(for: language) ?? ""

                let alert = AlertInformation(alertText: alertText, url: url, type: alertType, eventIssueTime: eventIssueTime, expiryTime: expiryTime, alertColourLevel: alertColourLevel)
                result.append(alert)
            }
        }

        return result
    }

    // MARK: - Helpers

    func isNight(_ periodName: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "(Ce soir|Soir et nuit|night)", options: [.caseInsensitive])
        let range = NSRange(periodName.startIndex..., in: periodName)
        return regex.firstMatch(in: periodName, options: [], range: range) != nil
    }

    func extractTendency(_ forecast: Forecast) -> Tendency {
        guard let tempClass = forecast.temperatures?.temperature?.first?.class?.value(for: .English) else {
            return .na
        }

        switch tempClass.lowercased() {
        case "high":
            return .maximum
        case "low":
            return .minimum
        default:
            return .na
        }
    }

    func extractAlertType(_ alertText: String) -> AlertType {
        let regex = try! NSRegularExpression(pattern: "(TERMINÉ|ENDED)", options: [.caseInsensitive])
        let range = NSRange(alertText.startIndex..., in: alertText)
        if regex.firstMatch(in: alertText, options: [], range: range) != nil {
            return .ended
        }
        return .warning
    }

    func formatObservationDate(_ isoTimestamp: String?) -> String {
        guard let timestamp = isoTimestamp else { return "" }

        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: timestamp) else { return timestamp }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: String(describing: language))
        if language == .French {
            dateFormatter.dateFormat = "d MMMM yyyy HH'h'mm"
        } else {
            dateFormatter.dateFormat = "d MMMM yyyy HH:mm"
        }
        return dateFormatter.string(from: date)
    }
}
