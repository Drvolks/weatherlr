//
//  WeatherHelperTests.swift
//  weatherlrTests
//

import XCTest
import UIKit
@testable import weatherlr

class WeatherHelperTests: XCTestCase {

    // MARK: - getImageSubstitute

    func testGetImageSubstituteMainlyClear() {
        XCTAssertEqual(.mainlySunny, WeatherHelper.getImageSubstitute(.mainlyClear))
    }

    func testGetImageSubstituteLightSnowFamily() {
        XCTAssertEqual(.lightSnow, WeatherHelper.getImageSubstitute(.aFewFlurries))
        XCTAssertEqual(.lightSnow, WeatherHelper.getImageSubstitute(.lightSnowshower))
        XCTAssertEqual(.lightSnow, WeatherHelper.getImageSubstitute(.periodsOfLightSnow))
        XCTAssertEqual(.lightSnow, WeatherHelper.getImageSubstitute(.periodsOfSnow))
    }

    func testGetImageSubstituteLightRainFamily() {
        XCTAssertEqual(.lightRain, WeatherHelper.getImageSubstitute(.aFewShowers))
        XCTAssertEqual(.lightRain, WeatherHelper.getImageSubstitute(.lightRainshower))
        XCTAssertEqual(.lightRain, WeatherHelper.getImageSubstitute(.showers))
        XCTAssertEqual(.lightRain, WeatherHelper.getImageSubstitute(.periodsOfRain))
        XCTAssertEqual(.lightRain, WeatherHelper.getImageSubstitute(.chanceOfRain))
    }

    func testGetImageSubstitutePartlyCloudyFamily() {
        XCTAssertEqual(.aFewClouds, WeatherHelper.getImageSubstitute(.partlyCloudy))
        XCTAssertEqual(.aFewClouds, WeatherHelper.getImageSubstitute(.aMixOfSunAndCloud))
        XCTAssertEqual(.aFewClouds, WeatherHelper.getImageSubstitute(.cloudyPeriods))
    }

    func testGetImageSubstituteFogFamily() {
        XCTAssertEqual(.mist, WeatherHelper.getImageSubstitute(.fog))
        XCTAssertEqual(.mist, WeatherHelper.getImageSubstitute(.haze))
        XCTAssertEqual(.mist, WeatherHelper.getImageSubstitute(.fogPatches))
        XCTAssertEqual(.mist, WeatherHelper.getImageSubstitute(.fogDissipating))
    }

    func testGetImageSubstituteThunderFamily() {
        XCTAssertEqual(.chanceOfShowersOrThunderstorms, WeatherHelper.getImageSubstitute(.thunderstorm))
        XCTAssertEqual(.chanceOfShowersOrThunderstorms, WeatherHelper.getImageSubstitute(.chanceOfThunderstorms))
    }

    func testGetImageSubstituteOvercastToCloudy() {
        XCTAssertEqual(.cloudy, WeatherHelper.getImageSubstitute(.overcast))
    }

    func testGetImageSubstituteNoMatchReturnsNil() {
        XCTAssertNil(WeatherHelper.getImageSubstitute(.sunny))
        XCTAssertNil(WeatherHelper.getImageSubstitute(.cloudy))
        XCTAssertNil(WeatherHelper.getImageSubstitute(.rain))
        XCTAssertNil(WeatherHelper.getImageSubstitute(.snow))
    }

    // MARK: - getNightImageName

    func testGetNightImageNameSunnyFamily() {
        XCTAssertEqual("clear", WeatherHelper.getNightImageName(.sunny))
        XCTAssertEqual("clear", WeatherHelper.getNightImageName(.mainlySunny))
        XCTAssertEqual("clear", WeatherHelper.getNightImageName(.clear))
    }

    func testGetNightImageNameCloudsFamily() {
        XCTAssertEqual("aFewCloudsNight", WeatherHelper.getNightImageName(.aFewClouds))
        XCTAssertEqual("aFewCloudsNight", WeatherHelper.getNightImageName(.aMixOfSunAndCloud))
        XCTAssertEqual("aFewCloudsNight", WeatherHelper.getNightImageName(.cloudyPeriods))
        XCTAssertEqual("aFewCloudsNight", WeatherHelper.getNightImageName(.partlyCloudy))
    }

    func testGetNightImageNameClearingAndMostlyCloudy() {
        XCTAssertEqual("clearingNight", WeatherHelper.getNightImageName(.clearing))
        XCTAssertEqual("clearingNight", WeatherHelper.getNightImageName(.mostlyCloudy))
    }

    func testGetNightImageNameDefaultNil() {
        XCTAssertNil(WeatherHelper.getNightImageName(.rain))
        XCTAssertNil(WeatherHelper.getNightImageName(.snow))
        XCTAssertNil(WeatherHelper.getNightImageName(.fog))
    }

    // MARK: - imageNameForIconCode

    func testImageNameForIconCodeKnown() {
        XCTAssertEqual("sunny", WeatherHelper.imageNameForIconCode(0))
        XCTAssertEqual("mainlySunny", WeatherHelper.imageNameForIconCode(1))
        XCTAssertEqual("aFewClouds", WeatherHelper.imageNameForIconCode(2))
        XCTAssertEqual("mostlyCloudy", WeatherHelper.imageNameForIconCode(3))
        XCTAssertEqual("rain", WeatherHelper.imageNameForIconCode(13))
        XCTAssertEqual("lightSnow", WeatherHelper.imageNameForIconCode(16))
        XCTAssertEqual("blizzard", WeatherHelper.imageNameForIconCode(18))
        XCTAssertEqual("clear", WeatherHelper.imageNameForIconCode(30))
        XCTAssertEqual("aFewCloudsNight", WeatherHelper.imageNameForIconCode(31))
        XCTAssertEqual("clearingNight", WeatherHelper.imageNameForIconCode(35))
        XCTAssertEqual("smoke", WeatherHelper.imageNameForIconCode(44))
    }

    func testImageNameForIconCodeUnknownReturnsNil() {
        XCTAssertNil(WeatherHelper.imageNameForIconCode(-1))
        XCTAssertNil(WeatherHelper.imageNameForIconCode(999))
        XCTAssertNil(WeatherHelper.imageNameForIconCode(29))
    }

    // MARK: - getMinMaxImageName

    func testGetMinMaxImageNameMaximum() {
        let info = WeatherInformation(temperature: 15, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .maximum, when: "",
                                      night: false, dateObservation: "")
        XCTAssertEqual("up", WeatherHelper.getMinMaxImageName(info))
    }

    func testGetMinMaxImageNameMinimum() {
        let info = WeatherInformation(temperature: 5, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .minimum, when: "",
                                      night: false, dateObservation: "")
        XCTAssertEqual("down", WeatherHelper.getMinMaxImageName(info))
    }

    func testGetMinMaxImageNameSteadyDay() {
        let info = WeatherInformation(temperature: 10, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .steady, when: "",
                                      night: false, dateObservation: "")
        XCTAssertEqual("up", WeatherHelper.getMinMaxImageName(info))
    }

    func testGetMinMaxImageNameSteadyNight() {
        let info = WeatherInformation(temperature: 10, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .steady, when: "",
                                      night: true, dateObservation: "")
        XCTAssertEqual("down", WeatherHelper.getMinMaxImageName(info))
    }

    // MARK: - getIndexAjust

    func testGetIndexAjustEmptyList() {
        XCTAssertEqual(1, WeatherHelper.getIndexAjust([]))
    }

    func testGetIndexAjustWithNowEntry() {
        let now = WeatherInformation(temperature: 0, weatherStatus: .na, weatherDay: .now,
                                     summary: "", detail: "", tendancy: .na, when: "",
                                     night: false, dateObservation: "")
        XCTAssertEqual(1, WeatherHelper.getIndexAjust([now]))
    }

    func testGetIndexAjustWithoutNowEntry() {
        let today = WeatherInformation(temperature: 0, weatherStatus: .na, weatherDay: .today,
                                       summary: "", detail: "", tendancy: .na, when: "",
                                       night: false, dateObservation: "")
        XCTAssertEqual(0, WeatherHelper.getIndexAjust([today]))
    }

    // MARK: - getWeatherTextWithMinMax

    func testGetWeatherTextWithMinMaxMaximum() {
        let info = WeatherInformation(temperature: 18, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .maximum, when: "",
                                      night: false, dateObservation: "")
        XCTAssertEqual("Max 18°", WeatherHelper.getWeatherTextWithMinMax(info))
    }

    func testGetWeatherTextWithMinMaxMinimum() {
        let info = WeatherInformation(temperature: 3, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .minimum, when: "",
                                      night: false, dateObservation: "")
        XCTAssertEqual("Min 3°", WeatherHelper.getWeatherTextWithMinMax(info))
    }

    func testGetWeatherTextWithMinMaxSteadyNight() {
        let info = WeatherInformation(temperature: 10, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .steady, when: "",
                                      night: true, dateObservation: "")
        XCTAssertEqual("10°", WeatherHelper.getWeatherTextWithMinMax(info))
    }

    func testGetWeatherTextWithMinMaxNegative() {
        let info = WeatherInformation(temperature: -5, weatherStatus: .snow, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .minimum, when: "",
                                      night: false, dateObservation: "")
        XCTAssertEqual("Min -5°", WeatherHelper.getWeatherTextWithMinMax(info))
    }

    // MARK: - addDaystoGivenDate

    func testAddDaysToGivenDate() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let plusOne = WeatherHelper.addDaystoGivenDate(base, NumberOfDaysToAdd: 1)
        let interval = plusOne.timeIntervalSince(base)
        XCTAssertEqual(86400, interval, accuracy: 3600) // allow 1h DST slack
    }

    func testAddDaysNegative() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let minusTwo = WeatherHelper.addDaystoGivenDate(base, NumberOfDaysToAdd: -2)
        XCTAssertTrue(minusTwo < base)
    }

    func testAddDaysZero() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let same = WeatherHelper.addDaystoGivenDate(base, NumberOfDaysToAdd: 0)
        XCTAssertEqual(base, same)
    }

    // MARK: - getMinMaxImage

    func testGetMinMaxImageNonHeaderReturnsImage() {
        let info = WeatherInformation(temperature: 10, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .maximum, when: "",
                                      night: false, dateObservation: "")
        let image = WeatherHelper.getMinMaxImage(info, header: false)
        // Must not crash, returns a UIImage (possibly the empty fallback)
        _ = image.size
    }

    // MARK: - textToImageMinMax

    func testTextToImageMinMaxReturnsImage() {
        let info = WeatherInformation(temperature: 12, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .maximum, when: "",
                                      night: false, dateObservation: "")
        let image = WeatherHelper.textToImageMinMax(info)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testTextToImageMinMaxSingleDigit() {
        let info = WeatherInformation(temperature: 5, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .maximum, when: "",
                                      night: false, dateObservation: "")
        let image = WeatherHelper.textToImageMinMax(info)
        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testTextToImageMinMaxThreeDigits() {
        let info = WeatherInformation(temperature: 100, weatherStatus: .sunny, weatherDay: .today,
                                      summary: "", detail: "", tendancy: .maximum, when: "",
                                      night: false, dateObservation: "")
        let image = WeatherHelper.textToImageMinMax(info)
        XCTAssertGreaterThan(image.size.width, 0)
    }

    // MARK: - getWeatherInformationsNoCache(_:city:) direct data parse

    func testGetWeatherInformationsNoCacheFromDataWrapsJsonParse() {
        let minimalJson = #"""
        {"type":"Feature","properties":{"currentConditions":{"temperature":{"value":{"en":10.0,"fr":10.0}},"condition":{"en":"Sunny","fr":"Ensoleillé"}},"forecastGroup":{"forecasts":[]}}}
        """#
        let data = minimalJson.data(using: .utf8)!
        let city = City(id: "qc-1", frenchName: "Test", englishName: "Test",
                        province: "QC", radarId: "", latitude: "", longitude: "")

        let wrapper = WeatherHelper.getWeatherInformationsNoCache(data, city: city)
        XCTAssertEqual(1, wrapper.weatherInformations.count) // .now entry
        XCTAssertEqual(.now, wrapper.weatherInformations.first?.weatherDay)
        XCTAssertEqual(10, wrapper.weatherInformations.first?.temperature)
        XCTAssertEqual("qc-1", wrapper.city?.id)
        XCTAssertFalse(wrapper.initialState)
    }
}
