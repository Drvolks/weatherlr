//
//  JsonWeatherParserTests.swift
//  weatherlrTests
//
//  Tests for the production JSON parser that consumes the Environment Canada
//  citypageweather-realtime API.
//

import XCTest
@testable import weatherlr

class JsonWeatherParserTests: XCTestCase {

    // MARK: - Fixtures

    /// Morning-style response: current conditions + Saturday day/night + Sunday day.
    private static let morningFixture: String = """
    {
      "type": "Feature",
      "id": "qc-147",
      "properties": {
        "currentConditions": {
          "iconCode": { "format": "png", "value": 3, "url": "" },
          "timestamp": { "en": "2026-04-11T12:00:00Z", "fr": "2026-04-11T12:00:00Z" },
          "temperature": { "value": { "en": 12.6, "fr": 12.6 } },
          "condition": { "en": "Mostly cloudy", "fr": "Généralement nuageux" },
          "windChill": { "value": { "en": 10, "fr": 10 } }
        },
        "forecastGroup": {
          "forecasts": [
            {
              "period": {
                "textForecastName": { "en": "Saturday", "fr": "Samedi" },
                "value": { "en": "Saturday", "fr": "Samedi" }
              },
              "temperatures": {
                "temperature": [{
                  "class": { "en": "high", "fr": "maximum" },
                  "value": { "en": 15.4, "fr": 15.4 }
                }]
              },
              "abbreviatedForecast": {
                "icon": { "format": "png", "value": 2, "url": "" },
                "textSummary": { "en": "A mix of sun and cloud", "fr": "Alternance de soleil et de nuages" }
              },
              "textSummary": { "en": "A mix of sun and cloud. High 15.", "fr": "Alternance de soleil et de nuages. Maximum 15." }
            },
            {
              "period": {
                "textForecastName": { "en": "Saturday night", "fr": "Samedi soir et nuit" },
                "value": { "en": "Saturday night", "fr": "Samedi soir et nuit" }
              },
              "temperatures": {
                "temperature": [{
                  "class": { "en": "low", "fr": "minimum" },
                  "value": { "en": 5.2, "fr": 5.2 }
                }]
              },
              "abbreviatedForecast": {
                "icon": { "format": "png", "value": 32, "url": "" },
                "textSummary": { "en": "Partly cloudy", "fr": "Partiellement nuageux" }
              },
              "textSummary": { "en": "Partly cloudy. Low 5.", "fr": "Partiellement nuageux. Minimum 5." }
            },
            {
              "period": {
                "textForecastName": { "en": "Sunday", "fr": "Dimanche" },
                "value": { "en": "Sunday", "fr": "Dimanche" }
              },
              "temperatures": {
                "temperature": [{
                  "class": { "en": "high", "fr": "maximum" },
                  "value": { "en": 18.0, "fr": 18.0 }
                }]
              },
              "abbreviatedForecast": {
                "icon": { "format": "png", "value": 0, "url": "" },
                "textSummary": { "en": "Sunny", "fr": "Ensoleillé" }
              },
              "textSummary": { "en": "Sunny. High 18.", "fr": "Ensoleillé. Maximum 18." }
            }
          ]
        },
        "hourlyForecastGroup": {
          "hourlyForecasts": [
            {
              "condition": { "en": "Mostly cloudy", "fr": "Généralement nuageux" },
              "temperature": { "value": { "en": 12, "fr": 12 } },
              "iconCode": { "format": "png", "value": 3, "url": "" },
              "lop": { "value": { "en": 10, "fr": 10 } },
              "timestamp": "2026-04-11T13:00:00Z"
            },
            {
              "condition": { "en": "Partly cloudy", "fr": "Partiellement nuageux" },
              "temperature": { "value": { "en": 13, "fr": 13 } },
              "iconCode": { "format": "png", "value": 2, "url": "" },
              "lop": { "value": { "en": 20, "fr": 20 } },
              "timestamp": "2026-04-11T14:00:00Z"
            },
            {
              "condition": { "en": "Sunny", "fr": "Ensoleillé" },
              "temperature": { "value": { "en": 15, "fr": 15 } },
              "iconCode": { "format": "png", "value": 0, "url": "" },
              "lop": { "value": { "en": 0, "fr": 0 } },
              "timestamp": "not-a-valid-timestamp"
            }
          ]
        },
        "warnings": [
          {
            "description": { "en": "Severe thunderstorm warning in effect", "fr": "Avertissement d'orages violents en vigueur" },
            "url": { "en": "https://weather.gc.ca/warnings/", "fr": "https://meteo.gc.ca/warnings/" },
            "type": { "en": "warning", "fr": "avertissement" },
            "expiryTime": { "en": "2026-04-11T20:00:00Z", "fr": "2026-04-11T20:00:00Z" },
            "eventIssue": { "en": "2026-04-11T12:00:00Z", "fr": "2026-04-11T12:00:00Z" },
            "alertColourLevel": { "en": "red", "fr": "rouge" }
          },
          {
            "description": { "en": "Rainfall warning ENDED", "fr": "Avertissement de pluie TERMINÉ" },
            "url": { "en": "https://weather.gc.ca/warnings/", "fr": "https://meteo.gc.ca/warnings/" },
            "type": { "en": "ended", "fr": "terminé" },
            "expiryTime": { "en": "2026-04-11T18:00:00Z", "fr": "2026-04-11T18:00:00Z" },
            "eventIssue": { "en": "2026-04-11T10:00:00Z", "fr": "2026-04-11T10:00:00Z" },
            "alertColourLevel": { "en": "", "fr": "" }
          },
          {
            "description": { "en": "", "fr": "" },
            "url": { "en": "", "fr": "" },
            "type": { "en": "warning", "fr": "avertissement" },
            "expiryTime": { "en": "", "fr": "" },
            "eventIssue": { "en": "", "fr": "" },
            "alertColourLevel": { "en": "", "fr": "" }
          }
        ]
      }
    }
    """

    /// Evening-style response: first forecast is "Tonight" (night), which should
    /// flip the `.now` entry's `night` flag.
    private static let eveningFixture: String = """
    {
      "type": "Feature",
      "id": "qc-147",
      "properties": {
        "currentConditions": {
          "iconCode": { "format": "png", "value": 30, "url": "" },
          "timestamp": { "en": "2026-04-11T22:00:00Z", "fr": "2026-04-11T22:00:00Z" },
          "temperature": { "value": { "en": 8.1, "fr": 8.1 } },
          "condition": { "en": "Clear", "fr": "Dégagé" }
        },
        "forecastGroup": {
          "forecasts": [
            {
              "period": {
                "textForecastName": { "en": "Tonight", "fr": "Ce soir et cette nuit" },
                "value": { "en": "Tonight", "fr": "Ce soir et cette nuit" }
              },
              "temperatures": {
                "temperature": [{
                  "class": { "en": "low", "fr": "minimum" },
                  "value": { "en": 4.0, "fr": 4.0 }
                }]
              },
              "abbreviatedForecast": {
                "icon": { "format": "png", "value": 30, "url": "" },
                "textSummary": { "en": "Clear", "fr": "Dégagé" }
              },
              "textSummary": { "en": "Clear. Low 4.", "fr": "Dégagé. Minimum 4." }
            },
            {
              "period": {
                "textForecastName": { "en": "Sunday", "fr": "Dimanche" },
                "value": { "en": "Sunday", "fr": "Dimanche" }
              },
              "temperatures": {
                "temperature": [{
                  "class": { "en": "high", "fr": "maximum" },
                  "value": { "en": 14.0, "fr": 14.0 }
                }]
              },
              "abbreviatedForecast": {
                "icon": { "format": "png", "value": 0, "url": "" },
                "textSummary": { "en": "Sunny", "fr": "Ensoleillé" }
              },
              "textSummary": { "en": "Sunny. High 14.", "fr": "Ensoleillé. Maximum 14." }
            }
          ]
        }
      }
    }
    """

    /// Response with no current-conditions condition text — parser must fall back
    /// to the first forecast's `abbreviatedForecast.textSummary`.
    private static let conditionFallbackFixture: String = """
    {
      "type": "Feature",
      "properties": {
        "currentConditions": {
          "iconCode": { "format": "png", "value": null, "url": "" },
          "timestamp": { "en": "2026-04-11T03:00:00Z", "fr": "2026-04-11T03:00:00Z" },
          "temperature": { "value": { "en": 2.3, "fr": 2.3 } }
        },
        "forecastGroup": {
          "forecasts": [
            {
              "period": {
                "textForecastName": { "en": "Tonight", "fr": "Ce soir et cette nuit" },
                "value": { "en": "Tonight", "fr": "Ce soir et cette nuit" }
              },
              "temperatures": {
                "temperature": [{
                  "value": { "en": 1.0, "fr": 1.0 }
                }]
              },
              "abbreviatedForecast": {
                "textSummary": { "en": "Cloudy", "fr": "Nuageux" }
              }
            }
          ]
        }
      }
    }
    """

    private func data(for fixture: String) -> Data {
        return fixture.data(using: .utf8)!
    }

    // MARK: - Full parse (English)

    func testMorningFixtureEnglish() {
        let parser = JsonWeatherParser(data: data(for: Self.morningFixture), language: .English)
        let (forecasts, alerts, hourly) = parser.parse()

        // .now + 3 forecasts
        XCTAssertEqual(4, forecasts.count)

        // Current conditions entry
        let now = forecasts[0]
        XCTAssertEqual(.now, now.weatherDay)
        XCTAssertEqual(13, now.temperature) // round(12.6)
        XCTAssertEqual(.mostlyCloudy, now.weatherStatus)
        XCTAssertEqual(3, now.iconCode)
        XCTAssertFalse(now.dateObservation.isEmpty)
        // Morning case: first forecast is NOT a night entry, so .now.night stays false
        XCTAssertFalse(now.night)

        // Entry 1: Saturday (day)
        let today = forecasts[1]
        XCTAssertEqual(.today, today.weatherDay)
        XCTAssertEqual(15, today.temperature) // round(15.4)
        XCTAssertFalse(today.night)
        XCTAssertEqual(.maximum, today.tendancy)
        XCTAssertEqual(2, today.iconCode)
        XCTAssertEqual("Saturday", today.when)

        // Entry 2: Saturday night — parser assigns .tomorow (known increment quirk)
        let saturdayNight = forecasts[2]
        XCTAssertTrue(saturdayNight.night)
        XCTAssertEqual(.minimum, saturdayNight.tendancy)
        XCTAssertEqual(5, saturdayNight.temperature) // round(5.2)
        XCTAssertEqual(32, saturdayNight.iconCode)

        // Entry 3: Sunday (day)
        let sunday = forecasts[3]
        XCTAssertFalse(sunday.night)
        XCTAssertEqual(.maximum, sunday.tendancy)
        XCTAssertEqual(18, sunday.temperature)
        XCTAssertEqual(0, sunday.iconCode)

        // Alerts: 1 active warning, 1 "ENDED" filtered, 1 empty-description filtered
        XCTAssertEqual(1, alerts.count)
        XCTAssertEqual(.warning, alerts[0].type)
        XCTAssertTrue(alerts[0].alertText.contains("Severe thunderstorm"))
        XCTAssertEqual("https://weather.gc.ca/warnings/", alerts[0].url)
        XCTAssertEqual("red", alerts[0].alertColourLevel)
        XCTAssertFalse(alerts[0].eventIssueTime.isEmpty)
        XCTAssertFalse(alerts[0].expiryTime.isEmpty)

        // Hourly: invalid timestamp skipped, 2 remain
        XCTAssertEqual(2, hourly.count)
        XCTAssertEqual(12, hourly[0].temperature)
        XCTAssertEqual(3, hourly[0].iconCode)
        XCTAssertEqual(10, hourly[0].precipChance)
        XCTAssertEqual(13, hourly[1].temperature)
        XCTAssertEqual(2, hourly[1].iconCode)
    }

    // MARK: - Full parse (French)

    func testMorningFixtureFrench() {
        let parser = JsonWeatherParser(data: data(for: Self.morningFixture), language: .French)
        let (forecasts, alerts, _) = parser.parse()

        XCTAssertEqual(4, forecasts.count)

        // "Samedi soir et nuit" should match the French side of the night regex
        let saturdayNight = forecasts[2]
        XCTAssertTrue(saturdayNight.night)
        XCTAssertEqual("Samedi soir et nuit", saturdayNight.when)

        // French alert description surfaces
        XCTAssertEqual(1, alerts.count)
        XCTAssertTrue(alerts[0].alertText.contains("orages violents"))
        XCTAssertEqual("rouge", alerts[0].alertColourLevel)

        // French observation date format uses "HH'h'mm"
        let now = forecasts[0]
        XCTAssertTrue(now.dateObservation.contains("h"))
    }

    // MARK: - Evening fixture — .now.night flips

    func testEveningFixtureFlagsNowAsNight() {
        let parser = JsonWeatherParser(data: data(for: Self.eveningFixture), language: .English)
        let (forecasts, _, _) = parser.parse()

        XCTAssertEqual(3, forecasts.count)
        let now = forecasts[0]
        XCTAssertEqual(.now, now.weatherDay)
        // First forecast is "Tonight" (night=true, weatherDay=.today) → .now.night flipped
        XCTAssertTrue(now.night)

        let tonight = forecasts[1]
        XCTAssertEqual(.today, tonight.weatherDay)
        XCTAssertTrue(tonight.night)
        XCTAssertEqual(.minimum, tonight.tendancy)
    }

    // MARK: - Condition text fallback

    func testCurrentConditionFallsBackToForecast() {
        let parser = JsonWeatherParser(data: data(for: Self.conditionFallbackFixture), language: .English)
        let (forecasts, _, _) = parser.parse()

        XCTAssertGreaterThanOrEqual(forecasts.count, 1)
        let now = forecasts[0]
        XCTAssertEqual(.now, now.weatherDay)
        // Fallback consumed the forecast's "Cloudy"
        XCTAssertEqual(.cloudy, now.weatherStatus)
        XCTAssertEqual(2, now.temperature) // round(2.3)
    }

    // MARK: - Degenerate inputs

    func testEmptyDataReturnsEmptyTuples() {
        let parser = JsonWeatherParser(data: Data(), language: .English)
        let (forecasts, alerts, hourly) = parser.parse()
        XCTAssertTrue(forecasts.isEmpty)
        XCTAssertTrue(alerts.isEmpty)
        XCTAssertTrue(hourly.isEmpty)
    }

    func testInvalidJsonReturnsEmptyTuples() {
        let parser = JsonWeatherParser(data: "not valid json".data(using: .utf8)!, language: .English)
        let (forecasts, alerts, hourly) = parser.parse()
        XCTAssertTrue(forecasts.isEmpty)
        XCTAssertTrue(alerts.isEmpty)
        XCTAssertTrue(hourly.isEmpty)
    }

    func testEmptyPropertiesReturnsEmpty() {
        let json = #"{"type":"Feature","id":"x","properties":{}}"#
        let parser = JsonWeatherParser(data: json.data(using: .utf8)!, language: .English)
        let (forecasts, alerts, hourly) = parser.parse()
        XCTAssertTrue(forecasts.isEmpty)
        XCTAssertTrue(alerts.isEmpty)
        XCTAssertTrue(hourly.isEmpty)
    }

    // MARK: - Private helpers exercised via the public parse()

    func testIsNightRegexMatchesKnownPatterns() {
        let parser = JsonWeatherParser(data: Data(), language: .English)
        XCTAssertTrue(parser.isNight("Tonight"))
        XCTAssertTrue(parser.isNight("Saturday night"))
        XCTAssertTrue(parser.isNight("Ce soir"))
        XCTAssertTrue(parser.isNight("Soir et nuit"))
        XCTAssertTrue(parser.isNight("Samedi soir et nuit"))
        XCTAssertFalse(parser.isNight("Saturday"))
        XCTAssertFalse(parser.isNight("Dimanche"))
        XCTAssertFalse(parser.isNight(""))
    }

    func testExtractAlertTypeDetectsEnded() {
        let parser = JsonWeatherParser(data: Data(), language: .English)
        XCTAssertEqual(.ended, parser.extractAlertType("Rainfall warning ENDED"))
        XCTAssertEqual(.ended, parser.extractAlertType("Avertissement TERMINÉ"))
        XCTAssertEqual(.warning, parser.extractAlertType("Severe thunderstorm warning in effect"))
    }
}
