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
    let alertAirFr = "BULLETIN SPÉCIAL SUR LA QUALITÉ DE L'AIR EN VIGUEUR, Fort St. John"
    let alertAirEn = "SPECIAL AIR QUALITY STATEMENT IN EFFECT, Fort St. John"
    let alertBlowingSnowFr = "AVIS DE POUDRERIE  EN VIGUEUR, Baie-James"
    let alertBlowingSnowEn = "BLOWING SNOW ADVISORY IN EFFECT, Baie-James"
    let alertFrostFr = "AVIS DE GEL EN VIGUEUR, Lorraine"
    let alertFrostEn = "FROST ADVISORY IN EFFECT, Mascouche"
    let alertFrostEndedFr = "AVIS DE BROUILLARD TERMINÉ, Lorraine"
    let alertFrostEndedEn = "FOG ADVISORY ENDED, Mascouche"
    
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
        /* Un cas de nuit */
        var parser = RssParserStub(xmlName: "TestData")!
        var rssEntries = parser.parse()
        
        var performer = RssEntryToWeatherInformation(rssEntries: rssEntries)
        var result = performer.perform()
        XCTAssertEqual(13, result.count)

        var current = result[0]
        XCTAssertNotNil(current)
        XCTAssertEqual(WeatherDay.Now, current.weatherDay)
        XCTAssertTrue(current.night)
        
        var today = result[1]
        XCTAssertNotNil(today)
        XCTAssertEqual(WeatherDay.Today, today.weatherDay)
        XCTAssertTrue(today.night)
        
        var tomorow = result[2]
        XCTAssertNotNil(tomorow)
        XCTAssertEqual(WeatherDay.Tomorow, tomorow.weatherDay)
        XCTAssertFalse(tomorow.night)
        
        
        /* Un cas de jour */
        parser = RssParserStub(xmlName: "TestData_EN")!
        rssEntries = parser.parse()
        
        performer = RssEntryToWeatherInformation(rssEntries: rssEntries)
        result = performer.perform()
        XCTAssertEqual(14, result.count)
        
        current = result[0]
        XCTAssertNotNil(current)
        XCTAssertEqual(WeatherDay.Now, current.weatherDay)
        XCTAssertFalse(current.night)
        
        today = result[1]
        XCTAssertNotNil(today)
        XCTAssertEqual(WeatherDay.Today, today.weatherDay)
        XCTAssertFalse(today.night)
        
        tomorow = result[2]
        XCTAssertNotNil(tomorow)
        XCTAssertEqual(WeatherDay.Tomorow, tomorow.weatherDay)
        XCTAssertTrue(tomorow.night)
    }
 
    func testConvertCurrent() {
        var parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        var rssEntry = RssEntry(parent: parser as RssParser)
        parser.parser.delegate = rssEntry
        parser.parser.parse()
        
        var performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        var result = performer.convert(rssEntry)
        
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
        result = performer.convert(rssEntry)
        XCTAssertEqual("Quelques nuages. Minimum moins 12.", result.detail)
        XCTAssertEqual(Tendency.Minimum, result.tendancy)
        XCTAssertTrue(result.night)
        
        parser = RssParserStub(xmlName: "TestDataEntry_EN")!
        rssEntry = RssEntry(parent: parser as RssParser)
        parser.parser.delegate = rssEntry
        parser.parser.parse()
        performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        result = performer.convert(rssEntry)
        XCTAssertEqual("Sunny. Wind north 20 km/h becoming west 20 near noon. High minus 2. UV index 4 or moderate.", result.detail)
        XCTAssertEqual(Tendency.Maximum, result.tendancy)
        XCTAssertFalse(result.night)
        
        parser = RssParserStub(xmlName: "TestDataEntryCurrentNoObservation")!
        rssEntry = RssEntry(parent: parser as RssParser)
        parser.parser.delegate = rssEntry
        parser.parser.parse()
        performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        result = performer.convert(rssEntry)
        XCTAssertEqual(WeatherDay.Now, result.weatherDay)
        XCTAssertEqual(-4, result.temperature)
        XCTAssertEqual(WeatherStatus.Blank, result.weatherStatus)
        XCTAssertEqual("Conditions actuelles: -3,5°C", result.summary)
        XCTAssertEqual(Tendency.NA, result.tendancy)
        XCTAssertEqual("Conditions actuelles", result.when)
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
        result = performer.convertWeatherStatus("Pluie ou neige")
        XCTAssertEqual(WeatherStatus.SnowOrRain, result)
        result = performer.convertWeatherStatus("Rain or snow")
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
        result = performer.convertWeatherStatus("Possibilité d'averses de neige ou de pluie")
        XCTAssertEqual(WeatherStatus.ChanceOfRainShowersOrFlurries, result)
        result = performer.convertWeatherStatus("Chance of flurries or rain showers")
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
        result = performer.convertWeatherStatus("Mainly Cloudy")
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
        
        // Snow
        result = performer.convertWeatherStatus("Neige")
        XCTAssertEqual(WeatherStatus.Snow, result)
        result = performer.convertWeatherStatus("Snow")
        XCTAssertEqual(WeatherStatus.Snow, result)
        
        // Showers
        result = performer.convertWeatherStatus("Averses")
        XCTAssertEqual(WeatherStatus.Showers, result)
        result = performer.convertWeatherStatus("Showers")
        XCTAssertEqual(WeatherStatus.Showers, result)
        
        // AFewShowers
        result = performer.convertWeatherStatus("Quelques averses")
        XCTAssertEqual(WeatherStatus.AFewShowers, result)
        result = performer.convertWeatherStatus("A few showers")
        XCTAssertEqual(WeatherStatus.AFewShowers, result)
        
        // ShowersOrDrizzle
        result = performer.convertWeatherStatus("Averses ou bruine")
        XCTAssertEqual(WeatherStatus.ShowersOrDrizzle, result)
        result = performer.convertWeatherStatus("Showers or drizzle")
        XCTAssertEqual(WeatherStatus.ShowersOrDrizzle, result)
        
        // PeriodsOfRainOrDrizzle
        result = performer.convertWeatherStatus("Pluie intermittente ou bruine")
        XCTAssertEqual(WeatherStatus.PeriodsOfRainOrDrizzle, result)
        result = performer.convertWeatherStatus("Periods of rain or drizzle")
        XCTAssertEqual(WeatherStatus.PeriodsOfRainOrDrizzle, result)
        
        // IncreasingCloudiness
        result = performer.convertWeatherStatus("Ennuagement")
        XCTAssertEqual(WeatherStatus.IncreasingCloudiness, result)
        result = performer.convertWeatherStatus("Increasing cloudiness")
        XCTAssertEqual(WeatherStatus.IncreasingCloudiness, result)
        
        // Flurries
        result = performer.convertWeatherStatus("Averses de neige")
        XCTAssertEqual(WeatherStatus.Flurries, result)
        result = performer.convertWeatherStatus("Flurries")
        XCTAssertEqual(WeatherStatus.Flurries, result)
        
        // ChanceOfDrizzle
        result = performer.convertWeatherStatus("Possibilité de bruine")
        XCTAssertEqual(WeatherStatus.ChanceOfDrizzle, result)
        result = performer.convertWeatherStatus("Chance of drizzle")
        XCTAssertEqual(WeatherStatus.ChanceOfDrizzle, result)
        
        // Drizzle
        result = performer.convertWeatherStatus("Bruine")
        XCTAssertEqual(WeatherStatus.Drizzle, result)
        result = performer.convertWeatherStatus("Drizzle")
        XCTAssertEqual(WeatherStatus.Drizzle, result)
        
        // PeriodsOfSnowOrRain
        result = performer.convertWeatherStatus("Neige intermittente ou pluie")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Periods of snow or rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Pluie et neige faibles")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Light Rain and Snow")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Faible neige intermittente ou pluie")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Periods of light snow or rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Quelques averses de neige ou de pluie")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("A few flurries or rain showers")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowOrRain, result)
        
        // LightFreezingDrizzle
        result = performer.convertWeatherStatus("Faible bruine verglaçante")
        XCTAssertEqual(WeatherStatus.LightFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Light Freezing Drizzle")
        XCTAssertEqual(WeatherStatus.LightFreezingDrizzle, result)
        
        // PeriodsOfFreezingRain
        result = performer.convertWeatherStatus("Pluie verglaçante intermittente")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingRain, result)
        result = performer.convertWeatherStatus("Periods of freezing rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingRain, result)
        
        // PeriodsOfRainOrFreezingRain
        result = performer.convertWeatherStatus("Pluie intermittente ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.PeriodsOfRainOrFreezingRain, result)
        result = performer.convertWeatherStatus("Periods of rain or freezing rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfRainOrFreezingRain, result)
        
        // PeriodsOfDrizzle
        result = performer.convertWeatherStatus("Bruine intermittente")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzle, result)
        result = performer.convertWeatherStatus("Periods of drizzle")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzle, result)
        result = performer.convertWeatherStatus("Bruine faible")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzle, result)
        result = performer.convertWeatherStatus("Light Drizzle")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzle, result)
        
        // FlurriesOrRainShowers
        result = performer.convertWeatherStatus("Averses de neige ou de pluie")
        XCTAssertEqual(WeatherStatus.FlurriesOrRainShowers, result)
        result = performer.convertWeatherStatus("Flurries or rain showers")
        XCTAssertEqual(WeatherStatus.FlurriesOrRainShowers, result)
        
        // PeriodsOfLightSnow
        result = performer.convertWeatherStatus("Faible neige intermittente")
        XCTAssertEqual(WeatherStatus.PeriodsOfLightSnow, result)
        result = performer.convertWeatherStatus("Periods of light snow")
        XCTAssertEqual(WeatherStatus.PeriodsOfLightSnow, result)
        
        // Blizzard
        result = performer.convertWeatherStatus("Blizzard")
        XCTAssertEqual(WeatherStatus.Blizzard, result)
        
        // LightSnowAndBlowingSnow
        result = performer.convertWeatherStatus("Neige faible et Poudrerie élevée")
        XCTAssertEqual(WeatherStatus.LightSnowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Light Snow and Blowing Snow")
        XCTAssertEqual(WeatherStatus.LightSnowAndBlowingSnow, result)
        
        // DriftingSnow
        result = performer.convertWeatherStatus("Poudrerie basse")
        XCTAssertEqual(WeatherStatus.DriftingSnow, result)
        result = performer.convertWeatherStatus("Drifting Snow")
        XCTAssertEqual(WeatherStatus.DriftingSnow, result)
        
        // Overcast
        result = performer.convertWeatherStatus("Couvert")
        XCTAssertEqual(WeatherStatus.Overcast, result)
        result = performer.convertWeatherStatus("Overcast")
        XCTAssertEqual(WeatherStatus.Overcast, result)
        
        // BlowingSnow
        result = performer.convertWeatherStatus("Poudrerie élevée")
        XCTAssertEqual(WeatherStatus.BlowingSnow, result)
        result = performer.convertWeatherStatus("Blowing Snow")
        XCTAssertEqual(WeatherStatus.BlowingSnow, result)
        result = performer.convertWeatherStatus("Poudrerie  élevée")
        XCTAssertEqual(WeatherStatus.BlowingSnow, result)
        result = performer.convertWeatherStatus("Poudrerie")
        XCTAssertEqual(WeatherStatus.BlowingSnow, result)

        // MainlyClear
        result = performer.convertWeatherStatus("Généralement dégagé")
        XCTAssertEqual(WeatherStatus.MainlyClear, result)
        result = performer.convertWeatherStatus("Mainly Clear")
        XCTAssertEqual(WeatherStatus.MainlyClear, result)
        
        // PeriodsOfLightSnowOrFreezingRain
        result = performer.convertWeatherStatus("Neige intermittente ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.PeriodsOfLightSnowOrFreezingRain, result)
        result = performer.convertWeatherStatus("Periods of light snow or freezing rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfLightSnowOrFreezingRain, result)
        result = performer.convertWeatherStatus("Faible neige intermittente ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.PeriodsOfLightSnowOrFreezingRain, result)
        result = performer.convertWeatherStatus("Periods of snow or freezing rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfLightSnowOrFreezingRain, result)
        
        // RainOrFreezingRain
        result = performer.convertWeatherStatus("Pluie ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.RainOrFreezingRain, result)
        result = performer.convertWeatherStatus("Rain or freezing rain")
        XCTAssertEqual(WeatherStatus.RainOrFreezingRain, result)
        
        // PeriodsOfRainMixedWithSnow
        result = performer.convertWeatherStatus("Pluie intermittente mêlée de neige")
        XCTAssertEqual(WeatherStatus.PeriodsOfRainMixedWithSnow, result)
        result = performer.convertWeatherStatus("Periods of rain mixed with snow")
        XCTAssertEqual(WeatherStatus.PeriodsOfRainMixedWithSnow, result)
        
        // PeriodsOfSnowAndBlowingSnow
        result = performer.convertWeatherStatus("Neige intermittente et poudrerie")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Periods of snow and blowing snow")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowAndBlowingSnow, result)
        
        // ChanceOfShowersOrDrizzle
        result = performer.convertWeatherStatus("Possibilité d'averses ou bruine")
        XCTAssertEqual(WeatherStatus.ChanceOfShowersOrDrizzle, result)
        result = performer.convertWeatherStatus("Chance of showers or drizzle")
        XCTAssertEqual(WeatherStatus.ChanceOfShowersOrDrizzle, result)
        
        // ChanceOfFrizzleMixedWithFreezingDrizzle
        result = performer.convertWeatherStatus("Bruine mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.DrizzleMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Drizzle mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.DrizzleMixedWithFreezingDrizzle, result)
        
        // LightSnowshower
        result = performer.convertWeatherStatus("Faible averse de neige")
        XCTAssertEqual(WeatherStatus.LightSnowshower, result)
        result = performer.convertWeatherStatus("Light Snowshower")
        XCTAssertEqual(WeatherStatus.LightSnowshower, result)
        
        // Possibilité de bruine mêlée de bruine verglaçante
        // Chance of drizzle mixed with freezing drizzle
        result = performer.convertWeatherStatus("Possibilité de bruine mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.ChanceOfDrizzleMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Chance of drizzle mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.ChanceOfDrizzleMixedWithFreezingDrizzle, result)
        
        // PeriodsOfDrizzleMixedWithFreezingDrizzle
        result = performer.convertWeatherStatus("Bruine intermittente mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzleMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of drizzle mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzleMixedWithFreezingDrizzle, result)
        
        // FreezingDrizzleOrDrizzle
        result = performer.convertWeatherStatus("Bruine verglaçante ou bruine")
        XCTAssertEqual(WeatherStatus.FreezingDrizzleOrDrizzle, result)
        result = performer.convertWeatherStatus("Freezing drizzle or drizzle")
        XCTAssertEqual(WeatherStatus.FreezingDrizzleOrDrizzle, result)
        
        // ChanceOfRainShowersOrWetFlurries
        result = performer.convertWeatherStatus("Possibilité d'averses de pluie ou de neige fondante")
        XCTAssertEqual(WeatherStatus.ChanceOfRainShowersOrWetFlurries, result)
        result = performer.convertWeatherStatus("Chance of rain showers or wet flurries")
        XCTAssertEqual(WeatherStatus.ChanceOfRainShowersOrWetFlurries, result)
        
        // SnowAndBlowingSnow
        result = performer.convertWeatherStatus("Neige et poudrerie")
        XCTAssertEqual(WeatherStatus.SnowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Snow and blowing snow")
        XCTAssertEqual(WeatherStatus.SnowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Neige et Poudrerie élevée")
        XCTAssertEqual(WeatherStatus.SnowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Neige parfois forte et poudrerie")
        XCTAssertEqual(WeatherStatus.SnowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Snow at times heavy and blowing snow")
        XCTAssertEqual(WeatherStatus.SnowAndBlowingSnow, result)
        
        // HeavySnow
        result = performer.convertWeatherStatus("Neige forte")
        XCTAssertEqual(WeatherStatus.HeavySnow, result)
        result = performer.convertWeatherStatus("Heavy Snow")
        XCTAssertEqual(WeatherStatus.HeavySnow, result)
        
        // FlurriesAtTimesHeavy
        result = performer.convertWeatherStatus("Averses de neige parfois fortes")
        XCTAssertEqual(WeatherStatus.FlurriesAtTimesHeavy, result)
        result = performer.convertWeatherStatus("Flurries at times heavy")
        XCTAssertEqual(WeatherStatus.FlurriesAtTimesHeavy, result)
        
        // SnowMixedWithRain
        result = performer.convertWeatherStatus("Neige mêlée de pluie")
        XCTAssertEqual(WeatherStatus.SnowMixedWithRain, result)
        result = performer.convertWeatherStatus("Snow mixed with rain")
        XCTAssertEqual(WeatherStatus.SnowMixedWithRain, result)
        
        // ChanceOfSnow
        result = performer.convertWeatherStatus("Possibilité de neige")
        XCTAssertEqual(WeatherStatus.ChanceOfSnow, result)
        result = performer.convertWeatherStatus("Chance of snow")
        XCTAssertEqual(WeatherStatus.ChanceOfSnow, result)
        
        // ChanceOfLightSnow
        result = performer.convertWeatherStatus("Possibilité de faible neige")
        XCTAssertEqual(WeatherStatus.ChanceOfLightSnow, result)
        result = performer.convertWeatherStatus("Chance of light snow")
        XCTAssertEqual(WeatherStatus.ChanceOfLightSnow, result)
        
        // SnowAtTimesHeavy
        result = performer.convertWeatherStatus("Neige parfois forte")
        XCTAssertEqual(WeatherStatus.SnowAtTimesHeavy, result)
        result = performer.convertWeatherStatus("Snow at times heavy")
        XCTAssertEqual(WeatherStatus.SnowAtTimesHeavy, result)
        
        // FreezingRainOrSnow
        result = performer.convertWeatherStatus("Pluie verglaçante ou neige")
        XCTAssertEqual(WeatherStatus.FreezingRainOrSnow, result)
        result = performer.convertWeatherStatus("Freezing rain or snow")
        XCTAssertEqual(WeatherStatus.FreezingRainOrSnow, result)
        
        // LightFreezingRain
        result = performer.convertWeatherStatus("Faible pluie verglaçante")
        XCTAssertEqual(WeatherStatus.LightFreezingRain, result)
        result = performer.convertWeatherStatus("Light freezing rain")
        XCTAssertEqual(WeatherStatus.LightFreezingRain, result)
        
        // IceCrystals
        result = performer.convertWeatherStatus("Cristaux de glace")
        XCTAssertEqual(WeatherStatus.IceCrystals, result)
        result = performer.convertWeatherStatus("Ice crystals")
        XCTAssertEqual(WeatherStatus.IceCrystals, result)
        
        // SnowGrains
        result = performer.convertWeatherStatus("Neige en grains")
        XCTAssertEqual(WeatherStatus.SnowGrains, result)
        result = performer.convertWeatherStatus("Snow grains")
        XCTAssertEqual(WeatherStatus.SnowGrains, result)
        
        // WetSnow
        result = performer.convertWeatherStatus("Neige fondante")
        XCTAssertEqual(WeatherStatus.WetSnow, result)
        result = performer.convertWeatherStatus("Wet snow")
        XCTAssertEqual(WeatherStatus.WetSnow, result)

        // WetFlurries
        result = performer.convertWeatherStatus("Averses de neige fondante")
        XCTAssertEqual(WeatherStatus.WetFlurries, result)
        result = performer.convertWeatherStatus("Wet flurries")
        XCTAssertEqual(WeatherStatus.WetFlurries, result)
        
        // FreezingFog
        result = performer.convertWeatherStatus("Brouillard givrant")
        XCTAssertEqual(WeatherStatus.FreezingFog, result)
        result = performer.convertWeatherStatus("Freezing fog")
        XCTAssertEqual(WeatherStatus.FreezingFog, result)
        
        // Fog
        result = performer.convertWeatherStatus("Brouillard")
        XCTAssertEqual(WeatherStatus.Fog, result)
        result = performer.convertWeatherStatus("Fog")
        XCTAssertEqual(WeatherStatus.Fog, result)
        
        // Haze
        result = performer.convertWeatherStatus("Brume sèche")
        XCTAssertEqual(WeatherStatus.Haze, result)
        result = performer.convertWeatherStatus("Haze")
        XCTAssertEqual(WeatherStatus.Haze, result)
        
        // SnowAtTimesHeavyMixedWithRain
        result = performer.convertWeatherStatus("Neige parfois forte mêlée de pluie")
        XCTAssertEqual(WeatherStatus.SnowAtTimesHeavyMixedWithRain, result)
        result = performer.convertWeatherStatus("Snow at times heavy mixed with rain")
        XCTAssertEqual(WeatherStatus.SnowAtTimesHeavyMixedWithRain, result)
        
        // PeriodsOfSnowMixedWithRain
        result = performer.convertWeatherStatus("Neige intermittente mêlée de pluie")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowMixedWithRain, result)
        result = performer.convertWeatherStatus("Periods of snow mixed with rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowMixedWithRain, result)

        // RainOrDrizzle
        result = performer.convertWeatherStatus("Pluie ou bruine")
        XCTAssertEqual(WeatherStatus.RainOrDrizzle, result)
        result = performer.convertWeatherStatus("Rain or drizzle")
        XCTAssertEqual(WeatherStatus.RainOrDrizzle, result)
        
        // PeriodsOfDrizzleOrRain
        result = performer.convertWeatherStatus("Bruine intermittente ou pluie")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzleOrRain, result)
        result = performer.convertWeatherStatus("Periods of drizzle or rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzleOrRain, result)
        
        // LightDrizzleAndFog
        result = performer.convertWeatherStatus("Bruine faible et brouillard")
        XCTAssertEqual(WeatherStatus.LightDrizzleAndFog, result)
        result = performer.convertWeatherStatus("Light drizzle and fog")
        XCTAssertEqual(WeatherStatus.LightDrizzleAndFog, result)
        
        // LightRainAndFog
        result = performer.convertWeatherStatus("Pluie faible et brouillard")
        XCTAssertEqual(WeatherStatus.LightRainAndFog, result)
        result = performer.convertWeatherStatus("Light rain and fog")
        XCTAssertEqual(WeatherStatus.LightRainAndFog, result)
        
        // PeriodsOfDrizzleMixedWithRain
        result = performer.convertWeatherStatus("Bruine intermittente mêlée de pluie")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzleMixedWithRain, result)
        result = performer.convertWeatherStatus("Periods of drizzle mixed with rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzleMixedWithRain, result)
        
        // PeriodsOfSnowMixedWithFreezingRain
        result = performer.convertWeatherStatus("Neige intermittente mêlée de pluie verglaçante")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowMixedWithFreezingRain, result)
        result = performer.convertWeatherStatus("Periods of snow mixed with freezing rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowMixedWithFreezingRain, result)
        
        // FogPatches
        result = performer.convertWeatherStatus("Bancs de brouillard")
        XCTAssertEqual(WeatherStatus.FogPatches, result)
        result = performer.convertWeatherStatus("Fog patches")
        XCTAssertEqual(WeatherStatus.FogPatches, result)
        
        // RainMixedWithSnow
        result = performer.convertWeatherStatus("Pluie mêlée de neige")
        XCTAssertEqual(WeatherStatus.RainMixedWithSnow, result)
        result = performer.convertWeatherStatus("Rain mixed with snow")
        XCTAssertEqual(WeatherStatus.RainMixedWithSnow, result)
        
        // SnowMixedWithIcePellets
        result = performer.convertWeatherStatus("Neige mêlée de grésil")
        XCTAssertEqual(WeatherStatus.SnowMixedWithIcePellets, result)
        result = performer.convertWeatherStatus("Snow mixed with ice pellets")
        XCTAssertEqual(WeatherStatus.SnowMixedWithIcePellets, result)
        
        // PeriodsOfLightSnowMixedWithFreezingDrizzle
        result = performer.convertWeatherStatus("Faible neige intermittente mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.PeriodsOfLightSnowMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of light snow mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.PeriodsOfLightSnowMixedWithFreezingDrizzle, result)
        
        // Smoke
        result = performer.convertWeatherStatus("Fumée")
        XCTAssertEqual(WeatherStatus.Smoke, result)
        result = performer.convertWeatherStatus("Smoke")
        XCTAssertEqual(WeatherStatus.Smoke, result)

        // SnowMixedWithFreezingDrizzle
        result = performer.convertWeatherStatus("Neige mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.SnowMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Snow mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.SnowMixedWithFreezingDrizzle, result)
        
        // PeriodsOfFreezingDrizzleOrDrizzle
        result = performer.convertWeatherStatus("Bruine verglaçante intermittente ou bruine")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingDrizzleOrDrizzle, result)
        result = performer.convertWeatherStatus("Periods of freezing drizzle or drizzle")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingDrizzleOrDrizzle, result)
        
        // ChanceOfDrizzleOrRain
        result = performer.convertWeatherStatus("Possibilité de bruine ou pluie")
        XCTAssertEqual(WeatherStatus.ChanceOfDrizzleOrRain, result)
        result = performer.convertWeatherStatus("Chance of drizzle or rain")
        XCTAssertEqual(WeatherStatus.ChanceOfDrizzleOrRain, result)
        
        // ChanceOfWetFlurries
        result = performer.convertWeatherStatus("Possibilité d'averses de neige fondante")
        XCTAssertEqual(WeatherStatus.ChanceOfWetFlurries, result)
        result = performer.convertWeatherStatus("Chance of wet flurries")
        XCTAssertEqual(WeatherStatus.ChanceOfWetFlurries, result)
        
        // PeriodsOfFreezingDrizzleOrRain
        result = performer.convertWeatherStatus("Bruine verglaçante intermittente ou pluie")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingDrizzleOrRain, result)
        result = performer.convertWeatherStatus("Periods of freezing drizzle or rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingDrizzleOrRain, result)
        
        // PeriodsOfFreezingDrizzle
        result = performer.convertWeatherStatus("Bruine verglaçante intermittente")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of freezing drizzle")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingDrizzle, result)
        
        // PeriodsOfFreezingRainOrSnow
        result = performer.convertWeatherStatus("Pluie verglaçante intermittente ou neige")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingRainOrSnow, result)
        result = performer.convertWeatherStatus("Periods of freezing rain or snow")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingRainOrSnow, result)
        
        // FreezingRainMixedWithIcePellets
        result = performer.convertWeatherStatus("Pluie verglaçante mêlée de grésil")
        XCTAssertEqual(WeatherStatus.FreezingRainMixedWithIcePellets, result)
        result = performer.convertWeatherStatus("Freezing rain mixed with ice pellets")
        XCTAssertEqual(WeatherStatus.FreezingRainMixedWithIcePellets, result)
        
        // PeriodsOfFreezingRainMixedWithIcePellets
        result = performer.convertWeatherStatus("Pluie verglaçante intermittente mêlée de grésil")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingRainMixedWithIcePellets, result)
        result = performer.convertWeatherStatus("Periods of freezing rain mixed with ice pellets")
        XCTAssertEqual(WeatherStatus.PeriodsOfFreezingRainMixedWithIcePellets, result)
        
        // ChanceOfShowersOrThunderstorms
        result = performer.convertWeatherStatus("Possibilité d'averses ou orages")
        XCTAssertEqual(WeatherStatus.ChanceOfShowersOrThunderstorms, result)
        result = performer.convertWeatherStatus("Chance of showers or thunderstorms")
        XCTAssertEqual(WeatherStatus.ChanceOfShowersOrThunderstorms, result)
        
        // ChanceOfWetFlurriesOrRainShowers
        result = performer.convertWeatherStatus("Possibilité d'averses de neige fondante ou de pluie")
        XCTAssertEqual(WeatherStatus.ChanceOfWetFlurriesOrRainShowers, result)
        result = performer.convertWeatherStatus("Chance of wet flurries or rain showers")
        XCTAssertEqual(WeatherStatus.ChanceOfWetFlurriesOrRainShowers, result)
        
        // ChanceOfRain
        result = performer.convertWeatherStatus("Possibilité de pluie")
        XCTAssertEqual(WeatherStatus.ChanceOfRain, result)
        result = performer.convertWeatherStatus("Chance of rain")
        XCTAssertEqual(WeatherStatus.ChanceOfRain, result)
        
        // LightWetSnow
        result = performer.convertWeatherStatus("Faible neige fondante")
        XCTAssertEqual(WeatherStatus.LightWetSnow, result)
        result = performer.convertWeatherStatus("Light wet snow")
        XCTAssertEqual(WeatherStatus.LightWetSnow, result)
        
        // Precipitation
        result = performer.convertWeatherStatus("Précipitations")
        XCTAssertEqual(WeatherStatus.Precipitation, result)
        result = performer.convertWeatherStatus("Precipitation")
        XCTAssertEqual(WeatherStatus.Precipitation, result)
        
        // DrizzleOrRain
        result = performer.convertWeatherStatus("Bruine ou pluie")
        XCTAssertEqual(WeatherStatus.DrizzleOrRain, result)
        result = performer.convertWeatherStatus("Drizzle or rain")
        XCTAssertEqual(WeatherStatus.DrizzleOrRain, result)
        
        // FreezingRainMixedWithSnow
        result = performer.convertWeatherStatus("Pluie verglaçante mêlée de neige")
        XCTAssertEqual(WeatherStatus.FreezingRainMixedWithSnow, result)
        result = performer.convertWeatherStatus("Freezing rain mixed with snow")
        XCTAssertEqual(WeatherStatus.FreezingRainMixedWithSnow, result)
        
        // FreezingDrizzleOrRain
        result = performer.convertWeatherStatus("Bruine verglaçante ou pluie")
        XCTAssertEqual(WeatherStatus.FreezingDrizzleOrRain, result)
        result = performer.convertWeatherStatus("Freezing drizzle or rain")
        XCTAssertEqual(WeatherStatus.FreezingDrizzleOrRain, result)
        
        // RainAtTimesHeavyOrDrizzle
        result = performer.convertWeatherStatus("Pluie parfois forte ou bruine")
        XCTAssertEqual(WeatherStatus.RainAtTimesHeavyOrDrizzle, result)
        result = performer.convertWeatherStatus("Rain at times heavy or drizzle")
        XCTAssertEqual(WeatherStatus.RainAtTimesHeavyOrDrizzle, result)
        
        // PeriodsOfLightSnowMixedWithRain
        result = performer.convertWeatherStatus("Faible neige intermittente mêlée de pluie")
        XCTAssertEqual(WeatherStatus.PeriodsOfLightSnowMixedWithRain, result)
        result = performer.convertWeatherStatus("Periods of light snow mixed with rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfLightSnowMixedWithRain, result)
        
        // AFewShowersOrDrizzle
        result = performer.convertWeatherStatus("Quelques averses ou bruine")
        XCTAssertEqual(WeatherStatus.AFewShowersOrDrizzle, result)
        result = performer.convertWeatherStatus("A few showers or drizzle")
        XCTAssertEqual(WeatherStatus.AFewShowersOrDrizzle, result)
        
        // PeriodsOfWetSnowOrRain
        result = performer.convertWeatherStatus("Neige fondante intermittente ou pluie")
        XCTAssertEqual(WeatherStatus.PeriodsOfWetSnowOrRain, result)
        result = performer.convertWeatherStatus("Periods of wet snow or rain")
        XCTAssertEqual(WeatherStatus.PeriodsOfWetSnowOrRain, result)
        
        // LightSnowMixedWithRain
        result = performer.convertWeatherStatus("Faible neige mêlée de pluie")
        XCTAssertEqual(WeatherStatus.LightSnowMixedWithRain, result)
        result = performer.convertWeatherStatus("Light snow mixed with rain")
        XCTAssertEqual(WeatherStatus.LightSnowMixedWithRain, result)

        // PeriodsOfDrizzleOrFreezingDrizzle
        result = performer.convertWeatherStatus("Bruine intermittente ou bruine verglaçante")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzleOrFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of drizzle or freezing drizzle")
        XCTAssertEqual(WeatherStatus.PeriodsOfDrizzleOrFreezingDrizzle, result)
        
        // PeriodsOfWetSnow
        result = performer.convertWeatherStatus("Neige fondante intermittente")
        XCTAssertEqual(WeatherStatus.PeriodsOfWetSnow, result)
        result = performer.convertWeatherStatus("Periods of wet snow")
        XCTAssertEqual(WeatherStatus.PeriodsOfWetSnow, result)

        // PeriodsOfSnowOrFreezingDrizzle
        result = performer.convertWeatherStatus("Neige intermittente ou bruine verglaçante")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowOrFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of snow or freezing drizzle")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowOrFreezingDrizzle, result)
        
        // ChanceOfFreezingDrizzle
        result = performer.convertWeatherStatus("Possibilité de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.ChanceOfFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Chance of freezing drizzle")
        XCTAssertEqual(WeatherStatus.ChanceOfFreezingDrizzle, result)
        
        // FreezingDrizzle
        result = performer.convertWeatherStatus("Bruine verglaçante")
        XCTAssertEqual(WeatherStatus.FreezingDrizzle, result)
        result = performer.convertWeatherStatus("Freezing drizzle")
        XCTAssertEqual(WeatherStatus.FreezingDrizzle, result)
        
        // PeriodsOfSnowMixedWithFreezingDrizzle
        result = performer.convertWeatherStatus("Neige intermittente mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of snow mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.PeriodsOfSnowMixedWithFreezingDrizzle, result)
        
        // LightSnowOrRain
        result = performer.convertWeatherStatus("Faible neige ou pluie")
        XCTAssertEqual(WeatherStatus.LightSnowOrRain, result)
        result = performer.convertWeatherStatus("Light snow or rain")
        XCTAssertEqual(WeatherStatus.LightSnowOrRain, result)
        
        // FreezingRain
        result = performer.convertWeatherStatus("Pluie verglaçante")
        XCTAssertEqual(WeatherStatus.FreezingRain, result)
        result = performer.convertWeatherStatus("Freezing rain")
        XCTAssertEqual(WeatherStatus.FreezingRain, result)
        
        // SnowOrFreezingRain
        result = performer.convertWeatherStatus("Neige ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.SnowOrFreezingRain, result)
        result = performer.convertWeatherStatus("Snow or freezing rain")
        XCTAssertEqual(WeatherStatus.SnowOrFreezingRain, result)

        // HeavyRainshower
        result = performer.convertWeatherStatus("Forte averse de pluie")
        XCTAssertEqual(WeatherStatus.HeavyRainshower, result)
        result = performer.convertWeatherStatus("Heavy rainshower")
        XCTAssertEqual(WeatherStatus.HeavyRainshower, result)
        
        // AFewShowersOrThunderstorms
        result = performer.convertWeatherStatus("Quelques averses ou orages")
        XCTAssertEqual(WeatherStatus.AFewShowersOrThunderstorms, result)
        result = performer.convertWeatherStatus("A few showers or thunderstorms")
        XCTAssertEqual(WeatherStatus.AFewShowersOrThunderstorms, result)
        
        // Thunderstorm
        result = performer.convertWeatherStatus("Orage")
        XCTAssertEqual(WeatherStatus.Thunderstorm, result)
        result = performer.convertWeatherStatus("Thunderstorm")
        XCTAssertEqual(WeatherStatus.Thunderstorm, result)
        
        // ThunderstormWithLightRainshowers
        result = performer.convertWeatherStatus("Orage avec averse de pluie")
        XCTAssertEqual(WeatherStatus.ThunderstormWithLightRainshowers, result)
        result = performer.convertWeatherStatus("Thunderstorm with light rainshowers")
        XCTAssertEqual(WeatherStatus.ThunderstormWithLightRainshowers, result)
        
        
        
        
        
        
        
        // Cloudy with X percent chance of flurries
        // Juste un cas pour convertWeatherStatusWithRegex
        result = performer.convertWeatherStatus("Nuageux avec 60 pour cent de probabilité d'averses de neige")
        XCTAssertEqual(WeatherStatus.CloudyWithXPercentChanceOfFlurries, result)
        result = performer.convertWeatherStatus("Cloudy with 60 percent chance of flurries")
        XCTAssertEqual(WeatherStatus.CloudyWithXPercentChanceOfFlurries, result)
        
        // No info
        result = performer.convertWeatherStatus("")
        XCTAssertEqual(WeatherStatus.NA, result)
        
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
        
        result = performer.extractWeatherConditionNowFromTitle("Conditions actuelles: 8,7")
        XCTAssertEqual("", result)
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
        
        result = performer.extractTemperature("Pluie. Températures à la baisse pour atteindre 8 en après-midi.")
        XCTAssertEqual("8", result)
        
        result = performer.extractTemperature("Rain. Temperature falling to 8 in the afternoon.")
        XCTAssertEqual("8", result)
        
        result = performer.extractTemperature("Ce soir et cette nuit: Neige. Températures à la hausse pour atteindre moins 9 au cours de la nuit.")
        XCTAssertEqual("moins 9", result)
        
        result = performer.extractTemperature("Tuesday night: Snow. Temperature rising to minus 9 by morning.")
        XCTAssertEqual("minus 9", result)
        
        result = performer.extractTemperature("Jeudi: Quelques averses de neige. Températures à la baisse pour atteindre zéro cet après-midi.")
        XCTAssertEqual("zéro", result)
        
        result = performer.extractTemperature("Thursday: A few flurries. Temperature falling to zero this afternoon.")
        XCTAssertEqual("zero", result)
        
        result = performer.extractTemperature("Wednesday: Showers. Temperature falling to 9 this morning then rising.")
        XCTAssertEqual("9", result)
        
        result = performer.extractTemperature("Mercredi: Averses. Températures à la baisse pour atteindre 9 ce matin puis à la hausse.")
        XCTAssertEqual("9", result)
    }
    
    func testConvertWeatherDay() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        
        // Conditions actuelles
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        var result = performer.convertWeatherDay("Conditions actuelles", currentDay: 0)
        XCTAssertEqual(WeatherDay.Now, result)
        result = performer.convertWeatherDay("Current Conditions", currentDay: 0)
        XCTAssertEqual(WeatherDay.Now, result)
        result = performer.convertWeatherDay("Conditions actuelles", currentDay: 3)
        XCTAssertEqual(WeatherDay.Now, result)
        
        // Prévisions météo
        result = performer.convertWeatherDay("Prévisions météo", currentDay: 0)
        XCTAssertEqual(WeatherDay.Today, result)
        result = performer.convertWeatherDay("Weather Forecasts", currentDay: 0)
        XCTAssertEqual(WeatherDay.Today, result)
        result = performer.convertWeatherDay("Prévisions météo", currentDay: 1)
        XCTAssertEqual(WeatherDay.Tomorow, result)
        result = performer.convertWeatherDay("Prévisions météo", currentDay: 2)
        XCTAssertEqual(WeatherDay.Day2, result)
        
        // Invalid data
        result = performer.convertWeatherDay("test", currentDay: 0)
        XCTAssertEqual(WeatherDay.NA, result)
        result = performer.convertWeatherDay("Prévisions météo", currentDay: 162)
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
        
        result = performer.isNight("Samedi soir et nuit: Dégagé. Minimum moins 2.")
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
        
        result = performer.isAlert(alertAirFr)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertAirEn)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertBlowingSnowFr)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertBlowingSnowEn)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertFrostFr)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertFrostEn)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertFrostEndedFr)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertFrostEndedEn)
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

        result = performer.extractAlertText(alertAirFr)
        XCTAssertEqual("BULLETIN SPÉCIAL SUR LA QUALITÉ DE L'AIR EN VIGUEUR", result)
        
        result = performer.extractAlertText(alertAirEn)
        XCTAssertEqual("SPECIAL AIR QUALITY STATEMENT IN EFFECT", result)
        
        result = performer.extractAlertText(alertBlowingSnowFr)
        XCTAssertEqual("AVIS DE POUDRERIE  EN VIGUEUR", result)
        
        result = performer.extractAlertText(alertBlowingSnowEn)
        XCTAssertEqual("BLOWING SNOW ADVISORY IN EFFECT", result)
        
        result = performer.extractAlertText(alertFrostFr)
        XCTAssertEqual("AVIS DE GEL EN VIGUEUR", result)
        
        result = performer.extractAlertText(alertFrostEn)
        XCTAssertEqual("FROST ADVISORY IN EFFECT", result)
        
        result = performer.extractAlertText(alertFrostEndedFr)
        XCTAssertEqual("AVIS DE BROUILLARD TERMINÉ", result)
        
        result = performer.extractAlertText(alertFrostEndedEn)
        XCTAssertEqual("FOG ADVISORY ENDED", result)
        
        result = performer.extractAlertText(alertTitleFr)
        XCTAssertEqual("", result)
        
        result = performer.extractAlertText(alertTitleEn)
        XCTAssertEqual("", result)
    }
    
    func testExtractAlertType() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractAlertType("AVIS DE BROUILLARD TERMINÉ")
        XCTAssertEqual(AlertType.Ended, result)
        
        result = performer.extractAlertType("FOG ADVISORY ENDED")
        XCTAssertEqual(AlertType.Ended, result)
        
        result = performer.extractAlertType("FROST ADVISORY IN EFFECT")
        XCTAssertEqual(AlertType.Warning, result)
        
        result = performer.extractAlertType("test")
        XCTAssertEqual(AlertType.Warning, result)
    }
}
