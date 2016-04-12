//
//  RssEntryToWeatherInformationTests.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-05.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import XCTest
@testable import weatherlr

class RssEntryToWeatherInformationTests: XCTestCase {
    let titleLowFr = "Vendredi soir et nuit: Possibilité d'averses de pluie ou de neige. Minimum moins 3. PdP 60%"
    let titleLowEn = "Friday night: Chance of rain showers or flurries. Low minus 3. POP 60%"
    let titleHighFr = "Vendredi: Pluie intermittente. Maximum plus 5."
    let titleHighEn = "Friday: Periods of rain. High plus 5."
    let titleCurrentFr = "Conditions actuelles: Généralement ensoleillé, -0,9°C"
    let titleCurrentEn = "Current Conditions: Mainly Sunny, -0.9°C"
    let summaryNowFr = "<b>Enregistrées à:</b> Aéroport int. de Montréal-Trudeau 17h00 HAE lundi 04 avril 2016 <br/>\n        <b>Condition:</b> Partiellement nuageux <br/>\n        <b>Température:</b> -3,5&deg;C <br/>\n        <b>Pression / Tendance:</b> 101,9 kPa à la baisse<br/>\n        <b>Visibilité:</b> 48,3 km<br/>\n        <b>Humidité:</b> 30 %<br/>\n        <b>Refroidissement éolien:</b> -5 <br/>\n        <b>Point de rosée:</b> -18,8&deg;C <br/>\n        <b>Vent:</b> NE 4 km/h<br/>\n        <b>Cote air santé:</b>  <br/>"
    let summaryNowEn = "<b>Observed at:</b> Montréal-Trudeau Int\'l Airport 08:00 AM EDT Tuesday 05 April 2016 <br/>\n        <b>Condition:</b> Mainly Sunny <br/>\n        <b>Temperature:</b> -8.2&deg;C <br/>\n        <b>Pressure / Tendency:</b> 103.0 kPa rising<br/>\n        <b>Visibility:</b> 24.1 km<br/>\n        <b>Humidity:</b> 48 %<br/>\n        <b>Wind Chill:</b> -14 <br/>\n        <b>Dewpoint:</b> -17.4&deg;C <br/>\n        <b>Wind:</b> NNE 14 km/h<br/>\n        <b>Air Quality Health Index:</b>  <br/>"
    let alertWithWarningTitleFr = "AVERTISSEMENT DE PLUIE EN VIGUEUR, Montréal"
    let alertWithWarningTitleEn = "RAINFALL WARNING IN EFFECT, Montréal"
    let alertWithReportTitleFr = "BULLETIN MÉTÉOROLOGIQUE SPÉCIAL EN VIGUEUR, Montréal"
    let alertWithReportTitleEn = "SPECIAL WEATHER STATEMENT IN EFFECT, Montréal"
    let alertTitleFr = "Aucune veille ou alerte en vigueur, Abbotsford"
    let alertTitleEn = "No watches or warnings in effect, Montréal"
    
    func testConstructor() {
        let parser = RssParserStub()!
        let rssEntry = RssEntry(parent: parser as RssParser)
        
        let result = RssEntryToWeatherInformation(rssEntry: rssEntry)
        XCTAssertNotNil(result)
        XCTAssertEqual(1, result.rssEntries.count)
    }
    
    func testConstructorArray() {
        let parser = RssParserStub()!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let rssEntries = [rssEntry]
        
        let result = RssEntryToWeatherInformation(rssEntries: rssEntries)
        XCTAssertNotNil(result)
        XCTAssertEqual(1, result.rssEntries.count)
    }
    
    func testPerform() {
        let parser = RssParserStub(xmlName: "TestData")!
        let rssEntries = parser.parse()
        
        let performer = RssEntryToWeatherInformation(rssEntries: rssEntries)
        var result = performer.perform()
        XCTAssertEqual(13, result.count)

        let current = result[0]
        XCTAssertNotNil(current)
        XCTAssertEqual(WeatherDay.Now, current.weatherDay)
        
        let today = result[1]
        XCTAssertNotNil(today)
        XCTAssertEqual(WeatherDay.Today, today.weatherDay)
    }
 
    func testConvertCurrent() {
        var parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        var rssEntry = RssEntry(parent: parser as RssParser)
        parser.parser.delegate = rssEntry
        parser.parser.parse()
        
        var performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        var result = performer.convert(rssEntry, position: 0)
        
        XCTAssertEqual(WeatherDay.Now, result.weatherDay)
        XCTAssertEqual(-4, result.temperature)
        XCTAssertEqual(WeatherStatus.PartlyCloudy, result.weatherStatus)
        XCTAssertEqual("Conditions actuelles: Partiellement nuageux, -3,5°C", result.summary)
        XCTAssertEqual(summaryNowFr, result.detail)
        XCTAssertEqual(Tendency.NA, result.tendancy)
        XCTAssertEqual("Conditions actuelles", result.when)
        XCTAssertFalse(result.night)
        
        parser = RssParserStub(xmlName: "TestDataEntry")!
        rssEntry = RssEntry(parent: parser as RssParser)
        parser.parser.delegate = rssEntry
        parser.parser.parse()
        performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        result = performer.convert(rssEntry, position: 2)
        XCTAssertEqual("Quelques nuages. Minimum moins 12.", result.detail)
        XCTAssertEqual(Tendency.Minimum, result.tendancy)
        XCTAssertTrue(result.night)
        
        parser = RssParserStub(xmlName: "TestDataEntry_EN")!
        rssEntry = RssEntry(parent: parser as RssParser)
        parser.parser.delegate = rssEntry
        parser.parser.parse()
        performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        result = performer.convert(rssEntry, position: 2)
        XCTAssertEqual("Sunny. Wind north 20 km/h becoming west 20 near noon. High minus 2. UV index 4 or moderate.", result.detail)
        XCTAssertEqual(Tendency.Maximum, result.tendancy)
        XCTAssertFalse(result.night)
    }
    
    func testConvertWeatherStatus() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        
        // PartlyCloudy
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        var result = performer.convertWeatherStatus("Partiellement nuageux")
        XCTAssertEqual(WeatherStatus.PartlyCloudy, result)
        result = performer.convertWeatherStatus("Partly cloudy")
        XCTAssertEqual(WeatherStatus.PartlyCloudy, result)

        // MainlySunny
        result = performer.convertWeatherStatus("Généralement ensoleillé")
        XCTAssertEqual(WeatherStatus.MainlySunny, result)
        result = performer.convertWeatherStatus("Mainly Sunny")
        XCTAssertEqual(WeatherStatus.MainlySunny, result)
        
        // Clear
        result = performer.convertWeatherStatus("Dégagé")
        XCTAssertEqual(WeatherStatus.Clear, result)
        result = performer.convertWeatherStatus("Clear")
        XCTAssertEqual(WeatherStatus.Clear, result)
        
        // LightSnow
        result = performer.convertWeatherStatus("Faible neige")
        XCTAssertEqual(WeatherStatus.LightSnow, result)
        result = performer.convertWeatherStatus("Light snow")
        XCTAssertEqual(WeatherStatus.LightSnow, result)
        
        // SnowOrRain
        result = performer.convertWeatherStatus("Neige ou pluie")
        XCTAssertEqual(WeatherStatus.SnowOrRain, result)
        result = performer.convertWeatherStatus("Snow or rain")
        XCTAssertEqual(WeatherStatus.SnowOrRain, result)
        
        // PeriodsOfRain
        result = performer.convertWeatherStatus("Pluie intermittente")
        XCTAssertEqual(WeatherStatus.PeriodsOfRain, result)
        result = performer.convertWeatherStatus("Periods of rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfRain, result)
        
        // ChanceOfRainShowersOrFlurries
        result = performer.convertWeatherStatus("Possibilité d'averses de pluie ou de neige")
        XCTAssertEqual(WeatherStatus.ChanceOfRainShowersOrFlurries, result)
        result = performer.convertWeatherStatus("Chance of rain showers or flurries")
        XCTAssertEqual(WeatherStatus.ChanceOfRainShowersOrFlurries, result)
        
        // ChanceOfFlurries
        result = performer.convertWeatherStatus("Possibilité d'averses de neige")
        XCTAssertEqual(WeatherStatus.ChanceOfFlurries, result)
        result = performer.convertWeatherStatus("Chance of flurries")
        XCTAssertEqual(WeatherStatus.ChanceOfFlurries, result)
        
        // CloudyPeriods
        result = performer.convertWeatherStatus("Passages nuageux")
        XCTAssertEqual(WeatherStatus.CloudyPeriods, result)
        result = performer.convertWeatherStatus("Cloudy periods")
        XCTAssertEqual(WeatherStatus.CloudyPeriods, result)
        
        // Sunny
        result = performer.convertWeatherStatus("Ensoleillé")
        XCTAssertEqual(WeatherStatus.Sunny, result)
        result = performer.convertWeatherStatus("Sunny")
        XCTAssertEqual(WeatherStatus.Sunny, result)
        
        // ChanceOfShowers
        result = performer.convertWeatherStatus("Possibilité d'averses")
        XCTAssertEqual(WeatherStatus.ChanceOfShowers, result)
        result = performer.convertWeatherStatus("Chance of showers")
        XCTAssertEqual(WeatherStatus.ChanceOfShowers, result)
        
        // MostlyCloudy
        result = performer.convertWeatherStatus("Généralement nuageux")
        XCTAssertEqual(WeatherStatus.MostlyCloudy, result)
        result = performer.convertWeatherStatus("Mostly Cloudy")
        XCTAssertEqual(WeatherStatus.MostlyCloudy, result)
        
        // Cloudy
        result = performer.convertWeatherStatus("Nuageux")
        XCTAssertEqual(WeatherStatus.Cloudy, result)
        result = performer.convertWeatherStatus("Cloudy")
        XCTAssertEqual(WeatherStatus.Cloudy, result)
        
        // LightRain
        result = performer.convertWeatherStatus("Pluie faible")
        XCTAssertEqual(WeatherStatus.LightRain, result)
        result = performer.convertWeatherStatus("Light Rain")
        XCTAssertEqual(WeatherStatus.LightRain, result)
        
        // Rain
        result = performer.convertWeatherStatus("Pluie")
        XCTAssertEqual(WeatherStatus.Rain, result)
        result = performer.convertWeatherStatus("Rain")
        XCTAssertEqual(WeatherStatus.Rain, result)
        
        // RainShowersOrFlurries
        result = performer.convertWeatherStatus("Averses de pluie ou de neige")
        XCTAssertEqual(WeatherStatus.RainShowersOrFlurries, result)
        result = performer.convertWeatherStatus("Rain showers or flurries")
        XCTAssertEqual(WeatherStatus.RainShowersOrFlurries, result)
        
        // PeriodsOfRainOrSnow
        result = performer.convertWeatherStatus("Pluie intermittente ou neige")
        XCTAssertEqual(WeatherStatus.PeriodsOfRainOrSnow, result)
        result = performer.convertWeatherStatus("Periods of rain or snow")
        XCTAssertEqual(WeatherStatus.PeriodsOfRainOrSnow, result)
        
        // PeriodsOfRainOrSnow
        result = performer.convertWeatherStatus("Neige intermittente")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnow, result)
        result = performer.convertWeatherStatus("Periods of snow")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnow, result)
        
        // AFewRainShowersOrFlurries
        result = performer.convertWeatherStatus("Quelques averses de pluie ou de neige")
        XCTAssertEqual(WeatherStatus.AFewRainShowersOrFlurries, result)
        result = performer.convertWeatherStatus("A few rain showers or flurries")
        XCTAssertEqual(WeatherStatus.AFewRainShowersOrFlurries, result)
        
        // AMixOfSunAndCloud
        result = performer.convertWeatherStatus("Alternance de soleil et de nuages")
        XCTAssertEqual(WeatherStatus.AMixOfSunAndCloud, result)
        result = performer.convertWeatherStatus("A mix of sun and cloud")
        XCTAssertEqual(WeatherStatus.AMixOfSunAndCloud, result)
        
        // RainAtTimesHeavy
        result = performer.convertWeatherStatus("Pluie parfois forte")
        XCTAssertEqual(WeatherStatus.RainAtTimesHeavy, result)
        result = performer.convertWeatherStatus("Rain at times heavy")
        XCTAssertEqual(WeatherStatus.RainAtTimesHeavy, result)
        
        // AFewFlurries
        result = performer.convertWeatherStatus("Quelques averses de neige")
        XCTAssertEqual(WeatherStatus.AFewFlurries, result)
        result = performer.convertWeatherStatus("A few flurries")
        XCTAssertEqual(WeatherStatus.AFewFlurries, result)
        
        // AFewClouds
        result = performer.convertWeatherStatus("Quelques nuages")
        XCTAssertEqual(WeatherStatus.AFewClouds, result)
        result = performer.convertWeatherStatus("A few clouds")
        XCTAssertEqual(WeatherStatus.AFewClouds, result)
        
        // Clearing
        result = performer.convertWeatherStatus("Dégagement")
        XCTAssertEqual(WeatherStatus.Clearing, result)
        result = performer.convertWeatherStatus("Clearing")
        XCTAssertEqual(WeatherStatus.Clearing, result)
        
        // Mist
        result = performer.convertWeatherStatus("Brume")
        XCTAssertEqual(WeatherStatus.Mist, result)
        result = performer.convertWeatherStatus("Mist")
        XCTAssertEqual(WeatherStatus.Mist, result)
        
        // LightRainshower
        result = performer.convertWeatherStatus("Faible averse de pluie")
        XCTAssertEqual(WeatherStatus.LightRainshower, result)
        result = performer.convertWeatherStatus("Light Rainshower")
        XCTAssertEqual(WeatherStatus.LightRainshower, result)
        
        // Cloudy with X percent chance of flurries
        // Juste un cas pour convertWeatherStatusWithRegex
        result = performer.convertWeatherStatus("Nuageux avec 60 pour cent de probabilité d'averses de neige")
        XCTAssertEqual(WeatherStatus.CloudyWithXPercentChanceOfFlurries, result)
        result = performer.convertWeatherStatus("Cloudy with 60 percent chance of flurries")
        XCTAssertEqual(WeatherStatus.CloudyWithXPercentChanceOfFlurries, result)
        
        // NA
        result = performer.convertWeatherStatus("test")
        XCTAssertEqual(WeatherStatus.NA, result)
    }
    
    func testConvertWeatherStatusWithRegex() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        
        // PartCloudy
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.convertWeatherStatusWithRegex("Nuageux avec 60 pour cent de probabilité d'averses de neige")
        XCTAssertEqual(WeatherStatus.CloudyWithXPercentChanceOfFlurries, result)
        result = performer.convertWeatherStatusWithRegex("Cloudy with 60 percent chance of flurries")
        XCTAssertEqual(WeatherStatus.CloudyWithXPercentChanceOfFlurries, result)
    }
    
    func testExtractWeatherConditionNowFromTitle() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractWeatherConditionNowFromTitle(titleCurrentFr)
        XCTAssertEqual("Généralement ensoleillé", result)
        
        result = performer.extractWeatherConditionNowFromTitle(titleCurrentEn)
        XCTAssertEqual("Mainly Sunny", result)
    }
    
    func testExtractTemperatureNowFromTitle() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractTemperatureNowFromTitle(titleCurrentFr)
        XCTAssertEqual("-0,9", result)
        
        result = performer.extractTemperatureNowFromTitle(titleCurrentEn)
        XCTAssertEqual("-0.9", result)
        
        result = performer.extractTemperatureNowFromTitle("Conditions actuelles: -10,4&#xB0;C")
        XCTAssertEqual("-10,4", result)
        
        result = performer.extractTemperatureNowFromTitle("Conditions actuelles: 10,4&#xB0;C")
        XCTAssertEqual("10,4", result)
    }
    
    func testExtractWeatherConditionNowFromSummary() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractWeatherConditionNowFromSummary(summaryNowFr)
        XCTAssertEqual("Partiellement nuageux", result)
        
        result = performer.extractWeatherConditionNowFromSummary(summaryNowEn)
        XCTAssertEqual("Mainly Sunny", result)
    }
    
    func testExtractTemperatureNowFromSummary() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractTemperatureNowFromSummary(summaryNowFr)
        XCTAssertEqual("-3,5", result)
        
        result = performer.extractTemperatureNowFromSummary(summaryNowEn)
        XCTAssertEqual("-8.2", result)
    }
    
    func testExtractWeatherCondition() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractWeatherCondition(titleLowFr)
        XCTAssertEqual("Possibilité d'averses de pluie ou de neige", result)
        
        result = performer.extractWeatherCondition(titleLowEn)
        XCTAssertEqual("Chance of rain showers or flurries", result)
        
        let title = "Samedi: Possibilité d'averses de neige. Maximum zéro. PdP 60%"
        result = performer.extractWeatherCondition(title)
        XCTAssertEqual("Possibilité d'averses de neige", result)
    }
    
    func testExtractTemperature() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractTemperature(titleLowFr)
        XCTAssertEqual("moins 3", result)
        
        result = performer.extractTemperature(titleLowEn)
        XCTAssertEqual("minus 3", result)
        
        result = performer.extractTemperature(titleHighFr)
        XCTAssertEqual("plus 5", result)
        
        result = performer.extractTemperature(titleHighEn)
        XCTAssertEqual("plus 5", result)
        
        result = performer.extractTemperature("Nuageux. Neige débutant tôt ce soir puis se changeant en pluie au cours de la nuit. Accumulation de neige de 2 à 4 cm. Vents du sud-est de 20 km/h avec rafales à 40. Minimum zéro. Températures à la hausse pour atteindre plus 2 au cours de la nuit.")
        XCTAssertEqual("zéro", result)
        
        result = performer.extractTemperature("Cloudy. Snow beginning early this evening then changing to rain overnight. Snowfall amount 2 to 4 cm. Wind southeast 20 km/h gusting to 40. Low zero with temperature rising to plus 2 by morning.")
        XCTAssertEqual("zero", result)
        
        result = performer.extractTemperature("Vendredi: Quelques averses de pluie ou de neige. Températures stables près de plus 3.")
        XCTAssertEqual("plus 3", result)
        
        result = performer.extractTemperature("Sunny. High 15 except 21 inland. UV index 5 or moderate.")
        XCTAssertEqual("15", result)
        
        result = performer.extractTemperature("Ensoleillé. Maximum 15 sauf 21 à l'intérieur. Indice UV de 5 ou modéré.")
        XCTAssertEqual("15", result)
    }
    
    func testConvertWeatherDay() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        
        // Conditions actuelles
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        var result = performer.convertWeatherDay("Conditions actuelles", position: 0)
        XCTAssertEqual(WeatherDay.Now, result)
        result = performer.convertWeatherDay("Current Conditions", position: 0)
        XCTAssertEqual(WeatherDay.Now, result)
        result = performer.convertWeatherDay("Conditions actuelles", position: 3)
        XCTAssertEqual(WeatherDay.Now, result)
        
        // Prévisions météo
        result = performer.convertWeatherDay("Prévisions météo", position: 1)
        XCTAssertEqual(WeatherDay.Today, result)
        result = performer.convertWeatherDay("Weather Forecasts", position: 1)
        XCTAssertEqual(WeatherDay.Today, result)
        result = performer.convertWeatherDay("Prévisions météo", position: 2)
        XCTAssertEqual(WeatherDay.Tomorow, result)
        result = performer.convertWeatherDay("Prévisions météo", position: 3)
        XCTAssertEqual(WeatherDay.NA, result)
        
        // Invalid data
        result = performer.convertWeatherDay("test", position: 0)
        XCTAssertEqual(WeatherDay.NA, result)
        result = performer.convertWeatherDay("Prévisions météo", position: 162)
        XCTAssertEqual(WeatherDay.NA, result)
    }
    
    func testConvertTemperature() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.convertTemperature("3,5")
        XCTAssertEqual(4, result)
        
        result = performer.convertTemperature("-3,5")
        XCTAssertEqual(-4, result)
        
        result = performer.convertTemperature("3.5")
        XCTAssertEqual(4, result)
        
        result = performer.convertTemperature("-3.5")
        XCTAssertEqual(-4, result)
        
        result = performer.convertTemperature("-3.2")
        XCTAssertEqual(-3, result)
        
        result = performer.convertTemperature("-3.9")
        XCTAssertEqual(-4, result)
        
        result = performer.convertTemperature("3")
        XCTAssertEqual(3, result)
        
        result = performer.convertTemperature("abc")
        XCTAssertEqual(0, result)
        
        result = performer.convertTemperature("zéro")
        XCTAssertEqual(0, result)
        
        result = performer.convertTemperature("zero")
        XCTAssertEqual(0, result)
    }
    
    func testConvertTemperatureWithTextSign() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.convertTemperatureWithTextSign("plus 3")
        XCTAssertEqual(3, result)
        
        result = performer.convertTemperatureWithTextSign("plus 3,5")
        XCTAssertEqual(4, result)
        
        result = performer.convertTemperatureWithTextSign("plus 3.5")
        XCTAssertEqual(4, result)
        
        result = performer.convertTemperatureWithTextSign("3")
        XCTAssertEqual(3, result)
        
        result = performer.convertTemperatureWithTextSign("3,5")
        XCTAssertEqual(4, result)
        
        result = performer.convertTemperatureWithTextSign("3.5")
        XCTAssertEqual(4, result)
        
        result = performer.convertTemperatureWithTextSign("moins 3")
        XCTAssertEqual(-3, result)
        
        result = performer.convertTemperatureWithTextSign("moins 3,5")
        XCTAssertEqual(-4, result)
        
        result = performer.convertTemperatureWithTextSign("moins 3.5")
        XCTAssertEqual(-4, result)

        result = performer.convertTemperatureWithTextSign("minus 3")
        XCTAssertEqual(-3, result)
        
        result = performer.convertTemperatureWithTextSign("minus 3,5")
        XCTAssertEqual(-4, result)
        
        result = performer.convertTemperatureWithTextSign("minus 3.5")
        XCTAssertEqual(-4, result)
        
        result = performer.convertTemperatureWithTextSign("minus 3.2")
        XCTAssertEqual(-3, result)
        
        result = performer.convertTemperatureWithTextSign("minus 3.9")
        XCTAssertEqual(-4, result)
        
        result = performer.convertTemperatureWithTextSign("abc")
        XCTAssertEqual(0, result)
        
        result = performer.convertTemperatureWithTextSign("minus abc")
        XCTAssertEqual(0, result)
        
        result = performer.convertTemperatureWithTextSign("25")
        XCTAssertEqual(25, result)
    }
    
    func testNettoyerDetail() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.nettoyerDetail("Pluie. Minimum plus 1. Prévisions émises 05h00 HAE mercredi 06 avril 2016")
        XCTAssertEqual("Pluie. Minimum plus 1.", result)
        
        result = performer.nettoyerDetail("Rain. Low plus 1. Forecast issued 05:00 AM EDT Wednesday 06 April 2016")
        XCTAssertEqual("Rain. Low plus 1.", result)
    }
    
    func testMaximumTemperature() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.isMaximumTemperature("Pluie. Minimum plus 1. Prévisions émises 05h00 HAE mercredi 06 avril 2016")
        XCTAssertFalse(result)
        
        result = performer.isMaximumTemperature("Rain. Low plus 1. Forecast issued 05:00 AM EDT Wednesday 06 April 2016")
        XCTAssertFalse(result)
        
        result = performer.isMaximumTemperature("Neige intermittente. Maximum plus 1. Prévisions émises 15h45 HAE lundi 04 avril 2016")
        XCTAssertTrue(result)
        
        result = performer.isMaximumTemperature("Periods of rain. High 9. Forecast issued 05:00 AM EDT Tuesday 05 April 2016")
        XCTAssertTrue(result)
    }
    
    func testNight() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.isNight("Thursday: Rain. High 9.")
        XCTAssertFalse(result)
        
        result = performer.isNight("Thursday night: Rain. Low plus 3.")
        XCTAssertTrue(result)
        
        result = performer.isNight("Jeudi: Pluie. Maximum 9.")
        XCTAssertFalse(result)
        
        result = performer.isNight("Ce soir et cette nuit: Pluie. Minimum plus 3.")
        XCTAssertTrue(result)
    }
    
    func testExtractWhen() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractWhen(titleLowFr)
        XCTAssertEqual("Vendredi soir et nuit", result)
        
        result = performer.extractWhen(titleLowEn)
        XCTAssertEqual("Friday night", result)
        
        result = performer.extractWhen(titleCurrentFr)
        XCTAssertEqual("Conditions actuelles", result)
        
        result = performer.extractWhen(titleCurrentEn)
        XCTAssertEqual("Current Conditions", result)
    }
    
    func testExtractTendency() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractTendency(titleLowFr)
        XCTAssertEqual(Tendency.Minimum, result)
        
        result = performer.extractTendency(titleLowEn)
        XCTAssertEqual(Tendency.Minimum, result)
        
        result = performer.extractTendency(titleHighFr)
        XCTAssertEqual(Tendency.Maximum, result)
        
        result = performer.extractTendency(titleHighEn)
        XCTAssertEqual(Tendency.Maximum, result)
        
        result = performer.extractTendency("Ce soir et cette nuit: Pluie parfois forte. Températures stables près de plus 3.")
        XCTAssertEqual(Tendency.Steady, result)
        
        result = performer.extractTendency("Thursday night: Rain at times heavy. Temperature steady near plus 3")
        XCTAssertEqual(Tendency.Steady, result)
    }
    
    func testIsAlert() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.isAlert(titleLowFr)
        XCTAssertFalse(result)
        
        result = performer.isAlert(titleLowEn)
        XCTAssertFalse(result)
        
        result = performer.isAlert(alertTitleFr)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertTitleEn)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertWithWarningTitleFr)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertWithWarningTitleEn)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertWithReportTitleFr)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertWithReportTitleEn)
        XCTAssertTrue(result)
    }
    
    func testExtractAlertText() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractAlertText(alertWithWarningTitleFr)
        XCTAssertEqual("AVERTISSEMENT DE PLUIE EN VIGUEUR", result)
        
        result = performer.extractAlertText("AVERTISSEMENT DE PLUIE EN VIGUEUR")
        XCTAssertEqual("AVERTISSEMENT DE PLUIE EN VIGUEUR", result)
        
        result = performer.extractAlertText(alertWithWarningTitleEn)
        XCTAssertEqual("RAINFALL WARNING IN EFFECT", result)
        
        result = performer.extractAlertText("AVERTISSEMENT DE PLUIE EN VIGUEUR")
        XCTAssertEqual("AVERTISSEMENT DE PLUIE EN VIGUEUR", result)
        
        result = performer.extractAlertText(alertWithWarningTitleEn)
        XCTAssertEqual("RAINFALL WARNING IN EFFECT", result)
        
        result = performer.extractAlertText(alertWithReportTitleFr)
        XCTAssertEqual("BULLETIN MÉTÉOROLOGIQUE SPÉCIAL EN VIGUEUR", result)
        
        result = performer.extractAlertText(alertWithReportTitleEn)
        XCTAssertEqual("SPECIAL WEATHER STATEMENT IN EFFECT", result)
        
        result = performer.extractAlertText(alertTitleFr)
        XCTAssertEqual("", result)
        
        result = performer.extractAlertText(alertTitleEn)
        XCTAssertEqual("", result)
    }
}
