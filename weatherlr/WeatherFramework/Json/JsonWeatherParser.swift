//
//  JsonWeatherParser.swift
//  weatherlr
//
//  Created by drvolks on 2026-02-12.
//  Copyright © 2026 drvolks. All rights reserved.
//

import Foundation

public class JsonWeatherParser {
    private static let nightRegex = try! NSRegularExpression(pattern: "(Ce soir|Soir et nuit|night)", options: [.caseInsensitive])
    // "60 percent chance of showers" / "60 pour cent de probabilité d'averses".
    // The daily forecast carries no POP field, so the only chance of rain the
    // API gives for a day is inside the cloudPrecip sentence.
    private static let popRegex = try! NSRegularExpression(pattern: "(\\d{1,3})\\s*(?:percent|pour cent)", options: [.caseInsensitive])
    private static let endedRegex = try! NSRegularExpression(pattern: "(TERMINÉ|ENDED)", options: [.caseInsensitive])

    let data: Data
    let language: Language
    let weatherStatusConverter = RssEntryToWeatherInformation(rssEntries: [RssEntry]())

    public init(data: Data, language: Language) {
        self.data = data
        self.language = language
    }

    public func parse() -> ([WeatherInformation], [AlertInformation], [HourlyForecastInfo]) {
        guard let response = try? JSONDecoder().decode(WeatherApiResponse.self, from: data) else {
            return ([], [], [])
        }

        let weatherInformations = buildWeatherInformations(response)
        let alerts = buildAlerts(response)
        let hourlyForecasts = buildHourlyForecasts(response)

        return (weatherInformations, alerts, hourlyForecasts)
    }

    // MARK: - Weather Informations

    func buildWeatherInformations(_ response: WeatherApiResponse) -> [WeatherInformation] {
        var result = [WeatherInformation]()
        var day = 0

        // Current conditions → .now entry
        if let cc = response.properties?.currentConditions,
           let tempValue = cc.temperature?.value?.value(for: language) {

            let temperature = Int(round(tempValue))

            // The hourly forecast group is reliably hour-fresh, whereas
            // `currentConditions` reports a station observation that can be silent
            // or lag reality. We prefer the first hourly forecast for the .now icon
            // and condition. See issue #22.
            let firstHourly = response.properties?.hourlyForecastGroup?.hourlyForecasts?.first

            let weatherStatus: WeatherStatus
            if let conditionText = cc.condition?.value(for: language), !conditionText.isEmpty {
                weatherStatus = weatherStatusConverter.convertWeatherStatus(conditionText)
            } else if let hourlyCondition = firstHourly?.condition?.value(for: language), !hourlyCondition.isEmpty {
                weatherStatus = weatherStatusConverter.convertWeatherStatus(hourlyCondition)
            } else if let firstForecast = response.properties?.forecastGroup?.forecasts?.first,
                      let fallbackText = firstForecast.abbreviatedForecast?.textSummary?.value(for: language), !fallbackText.isEmpty {
                // Last resort: this is a summary of the *entire* day, so it can
                // mention later rain and poison the now icon. Only used when
                // neither current conditions nor the hourly forecast report.
                weatherStatus = weatherStatusConverter.convertWeatherStatus(fallbackText)
            } else {
                weatherStatus = .blank
            }

            // Resolve the now icon. When current conditions and the hourly forecast
            // disagree, trust the hour-aligned forecast over the (often stale or
            // absent) current-conditions station reading.
            let resolvedIconCode: Int?
            if let ccIcon = cc.iconCode?.value,
               let hourlyIcon = firstHourly?.iconCode?.value,
               ccIcon != hourlyIcon {
                resolvedIconCode = hourlyIcon
            } else {
                resolvedIconCode = cc.iconCode?.value ?? firstHourly?.iconCode?.value
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
                dateObservation: dateObservation,
                iconCode: resolvedIconCode,
                precipChance: firstHourly?.lop?.value?.value(for: language)
            )
            result.append(now)
        }

        // Forecasts
        guard let forecasts = response.properties?.forecastGroup?.forecasts, !forecasts.isEmpty else {
            return result
        }

        for forecast in forecasts {
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
                dateObservation: "",
                iconCode: forecast.abbreviatedForecast?.icon?.value,
                precipChance: extractPop(forecast)
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
        let range = NSRange(periodName.startIndex..., in: periodName)
        return Self.nightRegex.firstMatch(in: periodName, options: [], range: range) != nil
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

    /// Pulls the probability of precipitation out of the forecast wording.
    func extractPop(_ forecast: Forecast) -> Int? {
        guard let text = forecast.cloudPrecip?.value(for: language) ?? forecast.textSummary?.value(for: language) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = Self.popRegex.firstMatch(in: text, options: [], range: range),
              let valueRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return Int(text[valueRange])
    }

    func extractAlertType(_ alertText: String) -> AlertType {
        let range = NSRange(alertText.startIndex..., in: alertText)
        if Self.endedRegex.firstMatch(in: alertText, options: [], range: range) != nil {
            return .ended
        }
        return .warning
    }

    // MARK: - Hourly Forecasts

    func buildHourlyForecasts(_ response: WeatherApiResponse) -> [HourlyForecastInfo] {
        guard let hourlyGroup = response.properties?.hourlyForecastGroup,
              let forecasts = hourlyGroup.hourlyForecasts else {
            return []
        }

        let isoFormatter = ISO8601DateFormatter()
        var result = [HourlyForecastInfo]()

        for forecast in forecasts {
            guard let timestamp = forecast.timestamp,
                  let date = isoFormatter.date(from: timestamp) else {
                continue
            }

            let temperature = forecast.temperature?.value?.value(for: language) ?? 0
            let iconCode = forecast.iconCode?.value
            let precipChance = forecast.lop?.value?.value(for: language) ?? 0

            result.append(HourlyForecastInfo(
                date: date,
                temperature: temperature,
                iconCode: iconCode,
                precipChance: precipChance
            ))
        }

        return result
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
