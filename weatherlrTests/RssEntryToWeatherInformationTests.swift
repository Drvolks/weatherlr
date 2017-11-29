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
    let summaryNowFr = "<b>Enregistrées à:</b> Aéroport int. de Montréal-Trudeau 17h00 HAE lundi 04 avril 2016 <br/>         <b>Condition:</b> Partiellement nuageux <br/>         <b>Température:</b> -3,5&deg;C <br/>         <b>Pression / Tendance:</b> 101,9 kPa à la baisse<br/>         <b>Visibilité:</b> 48,3 km<br/>         <b>Humidité:</b> 30 %<br/>         <b>Refroidissement éolien:</b> -5 <br/>         <b>Point de rosée:</b> -18,8&deg;C <br/>         <b>Vent:</b> NE 4 km/h<br/>         <b>Cote air santé:</b>  <br/>"
    let summaryNowEn = "<b>Observed at:</b> Montréal-Trudeau Int\'l Airport 08:00 AM EDT Tuesday 05 April 2016 <br/>         <b>Condition:</b> Mainly Sunny <br/>         <b>Temperature:</b> -8.2&deg;C <br/>         <b>Pressure / Tendency:</b> 103.0 kPa rising<br/>         <b>Visibility:</b> 24.1 km<br/>         <b>Humidity:</b> 48 %<br/>         <b>Wind Chill:</b> -14 <br/>         <b>Dewpoint:</b> -17.4&deg;C <br/>         <b>Wind:</b> NNE 14 km/h<br/>         <b>Air Quality Health Index:</b>  <br/>"
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
    let alertThunderFr = "ALERTE D'ORAGES VIOLENTS EN VIGUEUR, Lorraine"
    let alertThunderEn = "SEVERE THUNDERSTORM WARNING IN EFFECT, Mascouche"
    let alertThunderWatchFr = "VEILLE D'ORAGES VIOLENTS EN VIGUEUR, Lorraine"
    let alertThunderWatchEn = "SEVERE THUNDERSTORM WATCH IN EFFECT, Mascouche"
    
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
        XCTAssertEqual(WeatherDay.now, current.weatherDay)
        XCTAssertTrue(current.night)
        
        var today = result[1]
        XCTAssertNotNil(today)
        XCTAssertEqual(WeatherDay.today, today.weatherDay)
        XCTAssertTrue(today.night)
        
        var tomorow = result[2]
        XCTAssertNotNil(tomorow)
        XCTAssertEqual(WeatherDay.tomorow, tomorow.weatherDay)
        XCTAssertFalse(tomorow.night)
        
        
        /* Un cas de jour */
        parser = RssParserStub(xmlName: "TestData_EN")!
        rssEntries = parser.parse()
        
        performer = RssEntryToWeatherInformation(rssEntries: rssEntries)
        result = performer.perform()
        XCTAssertEqual(14, result.count)
        
        current = result[0]
        XCTAssertNotNil(current)
        XCTAssertEqual(WeatherDay.now, current.weatherDay)
        XCTAssertFalse(current.night)
        
        today = result[1]
        XCTAssertNotNil(today)
        XCTAssertEqual(WeatherDay.today, today.weatherDay)
        XCTAssertFalse(today.night)
        
        tomorow = result[2]
        XCTAssertNotNil(tomorow)
        XCTAssertEqual(WeatherDay.tomorow, tomorow.weatherDay)
        XCTAssertTrue(tomorow.night)
    }
 
    func testConvertCurrent() {
        var parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        var rssEntry = RssEntry(parent: parser as RssParser)
        parser.parser.delegate = rssEntry
        parser.parser.parse()
        
        var performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        var result = performer.convert(rssEntry)
        
        XCTAssertEqual(WeatherDay.now, result.weatherDay)
        XCTAssertEqual(-4, result.temperature)
        XCTAssertEqual(WeatherStatus.partlyCloudy, result.weatherStatus)
        XCTAssertEqual("Conditions actuelles: Partiellement nuageux, -3,5°C", result.summary)
        XCTAssertEqual(summaryNowFr, result.detail)
        XCTAssertEqual(Tendency.na, result.tendancy)
        XCTAssertEqual("Conditions actuelles", result.when)
        XCTAssertFalse(result.night)
        
        parser = RssParserStub(xmlName: "TestDataEntry")!
        rssEntry = RssEntry(parent: parser as RssParser)
        parser.parser.delegate = rssEntry
        parser.parser.parse()
        performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        result = performer.convert(rssEntry)
        XCTAssertEqual("Quelques nuages. Minimum moins 12.", result.detail)
        XCTAssertEqual(Tendency.minimum, result.tendancy)
        XCTAssertTrue(result.night)
        
        parser = RssParserStub(xmlName: "TestDataEntry_EN")!
        rssEntry = RssEntry(parent: parser as RssParser)
        parser.parser.delegate = rssEntry
        parser.parser.parse()
        performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        result = performer.convert(rssEntry)
        XCTAssertEqual("Sunny. Wind north 20 km/h becoming west 20 near noon. High minus 2. UV index 4 or moderate.", result.detail)
        XCTAssertEqual(Tendency.maximum, result.tendancy)
        XCTAssertFalse(result.night)
        
        parser = RssParserStub(xmlName: "TestDataEntryCurrentNoObservation")!
        rssEntry = RssEntry(parent: parser as RssParser)
        parser.parser.delegate = rssEntry
        parser.parser.parse()
        performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        result = performer.convert(rssEntry)
        XCTAssertEqual(WeatherDay.now, result.weatherDay)
        XCTAssertEqual(-4, result.temperature)
        XCTAssertEqual(WeatherStatus.blank, result.weatherStatus)
        XCTAssertEqual("Conditions actuelles: -3,5°C", result.summary)
        XCTAssertEqual(Tendency.na, result.tendancy)
        XCTAssertEqual("Conditions actuelles", result.when)
        XCTAssertFalse(result.night)
    }
    
    func testConvertWeatherStatus() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        
        // PartlyCloudy
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        var result = performer.convertWeatherStatus("Partiellement nuageux")
        XCTAssertEqual(WeatherStatus.partlyCloudy, result)
        result = performer.convertWeatherStatus("Partly cloudy")
        XCTAssertEqual(WeatherStatus.partlyCloudy, result)

        // MainlySunny
        result = performer.convertWeatherStatus("Généralement ensoleillé")
        XCTAssertEqual(WeatherStatus.mainlySunny, result)
        result = performer.convertWeatherStatus("Mainly Sunny")
        XCTAssertEqual(WeatherStatus.mainlySunny, result)
        
        // Clear
        result = performer.convertWeatherStatus("Dégagé")
        XCTAssertEqual(WeatherStatus.clear, result)
        result = performer.convertWeatherStatus("Clear")
        XCTAssertEqual(WeatherStatus.clear, result)
        
        // LightSnow
        result = performer.convertWeatherStatus("Faible neige")
        XCTAssertEqual(WeatherStatus.lightSnow, result)
        result = performer.convertWeatherStatus("Light snow")
        XCTAssertEqual(WeatherStatus.lightSnow, result)
        
        // SnowOrRain
        result = performer.convertWeatherStatus("Neige ou pluie")
        XCTAssertEqual(WeatherStatus.snowOrRain, result)
        result = performer.convertWeatherStatus("Snow or rain")
        XCTAssertEqual(WeatherStatus.snowOrRain, result)
        result = performer.convertWeatherStatus("Pluie ou neige")
        XCTAssertEqual(WeatherStatus.snowOrRain, result)
        result = performer.convertWeatherStatus("Rain or snow")
        XCTAssertEqual(WeatherStatus.snowOrRain, result)
        
        // PeriodsOfRain
        result = performer.convertWeatherStatus("Pluie intermittente")
        XCTAssertEqual(WeatherStatus.periodsOfRain, result)
        result = performer.convertWeatherStatus("Periods of rain")
        XCTAssertEqual(WeatherStatus.periodsOfRain, result)
        
        // ChanceOfRainShowersOrFlurries
        result = performer.convertWeatherStatus("Possibilité d'averses de pluie ou de neige")
        XCTAssertEqual(WeatherStatus.chanceOfRainShowersOrFlurries, result)
        result = performer.convertWeatherStatus("Chance of rain showers or flurries")
        XCTAssertEqual(WeatherStatus.chanceOfRainShowersOrFlurries, result)
        result = performer.convertWeatherStatus("Possibilité d'averses de neige ou de pluie")
        XCTAssertEqual(WeatherStatus.chanceOfRainShowersOrFlurries, result)
        result = performer.convertWeatherStatus("Chance of flurries or rain showers")
        XCTAssertEqual(WeatherStatus.chanceOfRainShowersOrFlurries, result)
        
        // ChanceOfFlurries
        result = performer.convertWeatherStatus("Possibilité d'averses de neige")
        XCTAssertEqual(WeatherStatus.chanceOfFlurries, result)
        result = performer.convertWeatherStatus("Chance of flurries")
        XCTAssertEqual(WeatherStatus.chanceOfFlurries, result)
        
        // CloudyPeriods
        result = performer.convertWeatherStatus("Passages nuageux")
        XCTAssertEqual(WeatherStatus.cloudyPeriods, result)
        result = performer.convertWeatherStatus("Cloudy periods")
        XCTAssertEqual(WeatherStatus.cloudyPeriods, result)
        
        // Sunny
        result = performer.convertWeatherStatus("Ensoleillé")
        XCTAssertEqual(WeatherStatus.sunny, result)
        result = performer.convertWeatherStatus("Sunny")
        XCTAssertEqual(WeatherStatus.sunny, result)
        
        // ChanceOfShowers
        result = performer.convertWeatherStatus("Possibilité d'averses")
        XCTAssertEqual(WeatherStatus.chanceOfShowers, result)
        result = performer.convertWeatherStatus("Chance of showers")
        XCTAssertEqual(WeatherStatus.chanceOfShowers, result)
        
        // MostlyCloudy
        result = performer.convertWeatherStatus("Généralement nuageux")
        XCTAssertEqual(WeatherStatus.mostlyCloudy, result)
        result = performer.convertWeatherStatus("Mostly Cloudy")
        XCTAssertEqual(WeatherStatus.mostlyCloudy, result)
        result = performer.convertWeatherStatus("Mainly Cloudy")
        XCTAssertEqual(WeatherStatus.mostlyCloudy, result)
        
        // Cloudy
        result = performer.convertWeatherStatus("Nuageux")
        XCTAssertEqual(WeatherStatus.cloudy, result)
        result = performer.convertWeatherStatus("Cloudy")
        XCTAssertEqual(WeatherStatus.cloudy, result)
        
        // LightRain
        result = performer.convertWeatherStatus("Pluie faible")
        XCTAssertEqual(WeatherStatus.lightRain, result)
        result = performer.convertWeatherStatus("Light Rain")
        XCTAssertEqual(WeatherStatus.lightRain, result)
        
        // Rain
        result = performer.convertWeatherStatus("Pluie")
        XCTAssertEqual(WeatherStatus.rain, result)
        result = performer.convertWeatherStatus("Rain")
        XCTAssertEqual(WeatherStatus.rain, result)
        
        // RainShowersOrFlurries
        result = performer.convertWeatherStatus("Averses de pluie ou de neige")
        XCTAssertEqual(WeatherStatus.rainShowersOrFlurries, result)
        result = performer.convertWeatherStatus("Rain showers or flurries")
        XCTAssertEqual(WeatherStatus.rainShowersOrFlurries, result)
        
        // PeriodsOfRainOrSnow
        result = performer.convertWeatherStatus("Pluie intermittente ou neige")
        XCTAssertEqual(WeatherStatus.periodsOfRainOrSnow, result)
        result = performer.convertWeatherStatus("Periods of rain or snow")
        XCTAssertEqual(WeatherStatus.periodsOfRainOrSnow, result)
        
        // PeriodsOfRainOrSnow
        result = performer.convertWeatherStatus("Neige intermittente")
        XCTAssertEqual(WeatherStatus.periodsOfSnow, result)
        result = performer.convertWeatherStatus("Periods of snow")
        XCTAssertEqual(WeatherStatus.periodsOfSnow, result)
        
        // AFewRainShowersOrFlurries
        result = performer.convertWeatherStatus("Quelques averses de pluie ou de neige")
        XCTAssertEqual(WeatherStatus.aFewRainShowersOrFlurries, result)
        result = performer.convertWeatherStatus("A few rain showers or flurries")
        XCTAssertEqual(WeatherStatus.aFewRainShowersOrFlurries, result)
        
        // AMixOfSunAndCloud
        result = performer.convertWeatherStatus("Alternance de soleil et de nuages")
        XCTAssertEqual(WeatherStatus.aMixOfSunAndCloud, result)
        result = performer.convertWeatherStatus("A mix of sun and cloud")
        XCTAssertEqual(WeatherStatus.aMixOfSunAndCloud, result)
        
        // RainAtTimesHeavy
        result = performer.convertWeatherStatus("Pluie parfois forte")
        XCTAssertEqual(WeatherStatus.rainAtTimesHeavy, result)
        result = performer.convertWeatherStatus("Rain at times heavy")
        XCTAssertEqual(WeatherStatus.rainAtTimesHeavy, result)
        
        // AFewFlurries
        result = performer.convertWeatherStatus("Quelques averses de neige")
        XCTAssertEqual(WeatherStatus.aFewFlurries, result)
        result = performer.convertWeatherStatus("A few flurries")
        XCTAssertEqual(WeatherStatus.aFewFlurries, result)
        
        // AFewClouds
        result = performer.convertWeatherStatus("Quelques nuages")
        XCTAssertEqual(WeatherStatus.aFewClouds, result)
        result = performer.convertWeatherStatus("A few clouds")
        XCTAssertEqual(WeatherStatus.aFewClouds, result)
        
        // Clearing
        result = performer.convertWeatherStatus("Dégagement")
        XCTAssertEqual(WeatherStatus.clearing, result)
        result = performer.convertWeatherStatus("Clearing")
        XCTAssertEqual(WeatherStatus.clearing, result)
        
        // Mist
        result = performer.convertWeatherStatus("Brume")
        XCTAssertEqual(WeatherStatus.mist, result)
        result = performer.convertWeatherStatus("Mist")
        XCTAssertEqual(WeatherStatus.mist, result)
        
        // LightRainshower
        result = performer.convertWeatherStatus("Faible averse de pluie")
        XCTAssertEqual(WeatherStatus.lightRainshower, result)
        result = performer.convertWeatherStatus("Light Rainshower")
        XCTAssertEqual(WeatherStatus.lightRainshower, result)
        
        // Snow
        result = performer.convertWeatherStatus("Neige")
        XCTAssertEqual(WeatherStatus.snow, result)
        result = performer.convertWeatherStatus("Snow")
        XCTAssertEqual(WeatherStatus.snow, result)
        
        // Showers
        result = performer.convertWeatherStatus("Averses")
        XCTAssertEqual(WeatherStatus.showers, result)
        result = performer.convertWeatherStatus("Showers")
        XCTAssertEqual(WeatherStatus.showers, result)
        
        // AFewShowers
        result = performer.convertWeatherStatus("Quelques averses")
        XCTAssertEqual(WeatherStatus.aFewShowers, result)
        result = performer.convertWeatherStatus("A few showers")
        XCTAssertEqual(WeatherStatus.aFewShowers, result)
        
        // ShowersOrDrizzle
        result = performer.convertWeatherStatus("Averses ou bruine")
        XCTAssertEqual(WeatherStatus.showersOrDrizzle, result)
        result = performer.convertWeatherStatus("Showers or drizzle")
        XCTAssertEqual(WeatherStatus.showersOrDrizzle, result)
        
        // PeriodsOfRainOrDrizzle
        result = performer.convertWeatherStatus("Pluie intermittente ou bruine")
        XCTAssertEqual(WeatherStatus.periodsOfRainOrDrizzle, result)
        result = performer.convertWeatherStatus("Periods of rain or drizzle")
        XCTAssertEqual(WeatherStatus.periodsOfRainOrDrizzle, result)
        
        // IncreasingCloudiness
        result = performer.convertWeatherStatus("Ennuagement")
        XCTAssertEqual(WeatherStatus.increasingCloudiness, result)
        result = performer.convertWeatherStatus("Increasing cloudiness")
        XCTAssertEqual(WeatherStatus.increasingCloudiness, result)
        
        // Flurries
        result = performer.convertWeatherStatus("Averses de neige")
        XCTAssertEqual(WeatherStatus.flurries, result)
        result = performer.convertWeatherStatus("Flurries")
        XCTAssertEqual(WeatherStatus.flurries, result)
        
        // ChanceOfDrizzle
        result = performer.convertWeatherStatus("Possibilité de bruine")
        XCTAssertEqual(WeatherStatus.chanceOfDrizzle, result)
        result = performer.convertWeatherStatus("Chance of drizzle")
        XCTAssertEqual(WeatherStatus.chanceOfDrizzle, result)
        
        // Drizzle
        result = performer.convertWeatherStatus("Bruine")
        XCTAssertEqual(WeatherStatus.drizzle, result)
        result = performer.convertWeatherStatus("Drizzle")
        XCTAssertEqual(WeatherStatus.drizzle, result)
        
        // PeriodsOfSnowOrRain
        result = performer.convertWeatherStatus("Neige intermittente ou pluie")
        XCTAssertEqual(WeatherStatus.periodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Periods of snow or rain")
        XCTAssertEqual(WeatherStatus.periodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Pluie et neige faibles")
        XCTAssertEqual(WeatherStatus.periodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Light Rain and Snow")
        XCTAssertEqual(WeatherStatus.periodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Faible neige intermittente ou pluie")
        XCTAssertEqual(WeatherStatus.periodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Periods of light snow or rain")
        XCTAssertEqual(WeatherStatus.periodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Quelques averses de neige ou de pluie")
        XCTAssertEqual(WeatherStatus.periodsOfSnowOrRain, result)
        result = performer.convertWeatherStatus("A few flurries or rain showers")
        XCTAssertEqual(WeatherStatus.periodsOfSnowOrRain, result)
        
        // LightFreezingDrizzle
        result = performer.convertWeatherStatus("Faible bruine verglaçante")
        XCTAssertEqual(WeatherStatus.lightFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Light Freezing Drizzle")
        XCTAssertEqual(WeatherStatus.lightFreezingDrizzle, result)
        
        // PeriodsOfFreezingRain
        result = performer.convertWeatherStatus("Pluie verglaçante intermittente")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingRain, result)
        result = performer.convertWeatherStatus("Periods of freezing rain")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingRain, result)
        
        // PeriodsOfRainOrFreezingRain
        result = performer.convertWeatherStatus("Pluie intermittente ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.periodsOfRainOrFreezingRain, result)
        result = performer.convertWeatherStatus("Periods of rain or freezing rain")
        XCTAssertEqual(WeatherStatus.periodsOfRainOrFreezingRain, result)
        
        // PeriodsOfDrizzle
        result = performer.convertWeatherStatus("Bruine intermittente")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzle, result)
        result = performer.convertWeatherStatus("Periods of drizzle")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzle, result)
        result = performer.convertWeatherStatus("Bruine faible")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzle, result)
        result = performer.convertWeatherStatus("Light Drizzle")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzle, result)
        
        // FlurriesOrRainShowers
        result = performer.convertWeatherStatus("Averses de neige ou de pluie")
        XCTAssertEqual(WeatherStatus.flurriesOrRainShowers, result)
        result = performer.convertWeatherStatus("Flurries or rain showers")
        XCTAssertEqual(WeatherStatus.flurriesOrRainShowers, result)
        
        // PeriodsOfLightSnow
        result = performer.convertWeatherStatus("Faible neige intermittente")
        XCTAssertEqual(WeatherStatus.periodsOfLightSnow, result)
        result = performer.convertWeatherStatus("Periods of light snow")
        XCTAssertEqual(WeatherStatus.periodsOfLightSnow, result)
        
        // Blizzard
        result = performer.convertWeatherStatus("Blizzard")
        XCTAssertEqual(WeatherStatus.blizzard, result)
        
        // LightSnowAndBlowingSnow
        result = performer.convertWeatherStatus("Neige faible et Poudrerie élevée")
        XCTAssertEqual(WeatherStatus.lightSnowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Light Snow and Blowing Snow")
        XCTAssertEqual(WeatherStatus.lightSnowAndBlowingSnow, result)
        
        // DriftingSnow
        result = performer.convertWeatherStatus("Poudrerie basse")
        XCTAssertEqual(WeatherStatus.driftingSnow, result)
        result = performer.convertWeatherStatus("Drifting Snow")
        XCTAssertEqual(WeatherStatus.driftingSnow, result)
        
        // Overcast
        result = performer.convertWeatherStatus("Couvert")
        XCTAssertEqual(WeatherStatus.overcast, result)
        result = performer.convertWeatherStatus("Overcast")
        XCTAssertEqual(WeatherStatus.overcast, result)
        
        // BlowingSnow
        result = performer.convertWeatherStatus("Poudrerie élevée")
        XCTAssertEqual(WeatherStatus.blowingSnow, result)
        result = performer.convertWeatherStatus("Blowing Snow")
        XCTAssertEqual(WeatherStatus.blowingSnow, result)
        result = performer.convertWeatherStatus("Poudrerie  élevée")
        XCTAssertEqual(WeatherStatus.blowingSnow, result)
        result = performer.convertWeatherStatus("Poudrerie")
        XCTAssertEqual(WeatherStatus.blowingSnow, result)

        // MainlyClear
        result = performer.convertWeatherStatus("Généralement dégagé")
        XCTAssertEqual(WeatherStatus.mainlyClear, result)
        result = performer.convertWeatherStatus("Mainly Clear")
        XCTAssertEqual(WeatherStatus.mainlyClear, result)
        
        // PeriodsOfLightSnowOrFreezingRain
        result = performer.convertWeatherStatus("Neige intermittente ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.periodsOfLightSnowOrFreezingRain, result)
        result = performer.convertWeatherStatus("Periods of light snow or freezing rain")
        XCTAssertEqual(WeatherStatus.periodsOfLightSnowOrFreezingRain, result)
        result = performer.convertWeatherStatus("Faible neige intermittente ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.periodsOfLightSnowOrFreezingRain, result)
        result = performer.convertWeatherStatus("Periods of snow or freezing rain")
        XCTAssertEqual(WeatherStatus.periodsOfLightSnowOrFreezingRain, result)
        
        // RainOrFreezingRain
        result = performer.convertWeatherStatus("Pluie ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.rainOrFreezingRain, result)
        result = performer.convertWeatherStatus("Rain or freezing rain")
        XCTAssertEqual(WeatherStatus.rainOrFreezingRain, result)
        
        // PeriodsOfRainMixedWithSnow
        result = performer.convertWeatherStatus("Pluie intermittente mêlée de neige")
        XCTAssertEqual(WeatherStatus.periodsOfRainMixedWithSnow, result)
        result = performer.convertWeatherStatus("Periods of rain mixed with snow")
        XCTAssertEqual(WeatherStatus.periodsOfRainMixedWithSnow, result)
        
        // PeriodsOfSnowAndBlowingSnow
        result = performer.convertWeatherStatus("Neige intermittente et poudrerie")
        XCTAssertEqual(WeatherStatus.periodsOfSnowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Periods of snow and blowing snow")
        XCTAssertEqual(WeatherStatus.periodsOfSnowAndBlowingSnow, result)
        
        // ChanceOfShowersOrDrizzle
        result = performer.convertWeatherStatus("Possibilité d'averses ou bruine")
        XCTAssertEqual(WeatherStatus.chanceOfShowersOrDrizzle, result)
        result = performer.convertWeatherStatus("Chance of showers or drizzle")
        XCTAssertEqual(WeatherStatus.chanceOfShowersOrDrizzle, result)
        
        // ChanceOfFrizzleMixedWithFreezingDrizzle
        result = performer.convertWeatherStatus("Bruine mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.drizzleMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Drizzle mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.drizzleMixedWithFreezingDrizzle, result)
        
        // LightSnowshower
        result = performer.convertWeatherStatus("Faible averse de neige")
        XCTAssertEqual(WeatherStatus.lightSnowshower, result)
        result = performer.convertWeatherStatus("Light Snowshower")
        XCTAssertEqual(WeatherStatus.lightSnowshower, result)
        
        // Possibilité de bruine mêlée de bruine verglaçante
        // Chance of drizzle mixed with freezing drizzle
        result = performer.convertWeatherStatus("Possibilité de bruine mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.chanceOfDrizzleMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Chance of drizzle mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.chanceOfDrizzleMixedWithFreezingDrizzle, result)
        
        // PeriodsOfDrizzleMixedWithFreezingDrizzle
        result = performer.convertWeatherStatus("Bruine intermittente mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzleMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of drizzle mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzleMixedWithFreezingDrizzle, result)
        
        // FreezingDrizzleOrDrizzle
        result = performer.convertWeatherStatus("Bruine verglaçante ou bruine")
        XCTAssertEqual(WeatherStatus.freezingDrizzleOrDrizzle, result)
        result = performer.convertWeatherStatus("Freezing drizzle or drizzle")
        XCTAssertEqual(WeatherStatus.freezingDrizzleOrDrizzle, result)
        
        // ChanceOfRainShowersOrWetFlurries
        result = performer.convertWeatherStatus("Possibilité d'averses de pluie ou de neige fondante")
        XCTAssertEqual(WeatherStatus.chanceOfRainShowersOrWetFlurries, result)
        result = performer.convertWeatherStatus("Chance of rain showers or wet flurries")
        XCTAssertEqual(WeatherStatus.chanceOfRainShowersOrWetFlurries, result)
        
        // SnowAndBlowingSnow
        result = performer.convertWeatherStatus("Neige et poudrerie")
        XCTAssertEqual(WeatherStatus.snowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Snow and blowing snow")
        XCTAssertEqual(WeatherStatus.snowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Neige et Poudrerie élevée")
        XCTAssertEqual(WeatherStatus.snowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Neige parfois forte et poudrerie")
        XCTAssertEqual(WeatherStatus.snowAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Snow at times heavy and blowing snow")
        XCTAssertEqual(WeatherStatus.snowAndBlowingSnow, result)
        
        // HeavySnow
        result = performer.convertWeatherStatus("Neige forte")
        XCTAssertEqual(WeatherStatus.heavySnow, result)
        result = performer.convertWeatherStatus("Heavy Snow")
        XCTAssertEqual(WeatherStatus.heavySnow, result)
        
        // FlurriesAtTimesHeavy
        result = performer.convertWeatherStatus("Averses de neige parfois fortes")
        XCTAssertEqual(WeatherStatus.flurriesAtTimesHeavy, result)
        result = performer.convertWeatherStatus("Flurries at times heavy")
        XCTAssertEqual(WeatherStatus.flurriesAtTimesHeavy, result)
        
        // SnowMixedWithRain
        result = performer.convertWeatherStatus("Neige mêlée de pluie")
        XCTAssertEqual(WeatherStatus.snowMixedWithRain, result)
        result = performer.convertWeatherStatus("Snow mixed with rain")
        XCTAssertEqual(WeatherStatus.snowMixedWithRain, result)
        
        // ChanceOfSnow
        result = performer.convertWeatherStatus("Possibilité de neige")
        XCTAssertEqual(WeatherStatus.chanceOfSnow, result)
        result = performer.convertWeatherStatus("Chance of snow")
        XCTAssertEqual(WeatherStatus.chanceOfSnow, result)
        
        // ChanceOfLightSnow
        result = performer.convertWeatherStatus("Possibilité de faible neige")
        XCTAssertEqual(WeatherStatus.chanceOfLightSnow, result)
        result = performer.convertWeatherStatus("Chance of light snow")
        XCTAssertEqual(WeatherStatus.chanceOfLightSnow, result)
        
        // SnowAtTimesHeavy
        result = performer.convertWeatherStatus("Neige parfois forte")
        XCTAssertEqual(WeatherStatus.snowAtTimesHeavy, result)
        result = performer.convertWeatherStatus("Snow at times heavy")
        XCTAssertEqual(WeatherStatus.snowAtTimesHeavy, result)
        
        // FreezingRainOrSnow
        result = performer.convertWeatherStatus("Pluie verglaçante ou neige")
        XCTAssertEqual(WeatherStatus.freezingRainOrSnow, result)
        result = performer.convertWeatherStatus("Freezing rain or snow")
        XCTAssertEqual(WeatherStatus.freezingRainOrSnow, result)
        
        // LightFreezingRain
        result = performer.convertWeatherStatus("Faible pluie verglaçante")
        XCTAssertEqual(WeatherStatus.lightFreezingRain, result)
        result = performer.convertWeatherStatus("Light freezing rain")
        XCTAssertEqual(WeatherStatus.lightFreezingRain, result)
        
        // IceCrystals
        result = performer.convertWeatherStatus("Cristaux de glace")
        XCTAssertEqual(WeatherStatus.iceCrystals, result)
        result = performer.convertWeatherStatus("Ice crystals")
        XCTAssertEqual(WeatherStatus.iceCrystals, result)
        
        // SnowGrains
        result = performer.convertWeatherStatus("Neige en grains")
        XCTAssertEqual(WeatherStatus.snowGrains, result)
        result = performer.convertWeatherStatus("Snow grains")
        XCTAssertEqual(WeatherStatus.snowGrains, result)
        
        // WetSnow
        result = performer.convertWeatherStatus("Neige fondante")
        XCTAssertEqual(WeatherStatus.wetSnow, result)
        result = performer.convertWeatherStatus("Wet snow")
        XCTAssertEqual(WeatherStatus.wetSnow, result)

        // WetFlurries
        result = performer.convertWeatherStatus("Averses de neige fondante")
        XCTAssertEqual(WeatherStatus.wetFlurries, result)
        result = performer.convertWeatherStatus("Wet flurries")
        XCTAssertEqual(WeatherStatus.wetFlurries, result)
        
        // FreezingFog
        result = performer.convertWeatherStatus("Brouillard givrant")
        XCTAssertEqual(WeatherStatus.freezingFog, result)
        result = performer.convertWeatherStatus("Freezing fog")
        XCTAssertEqual(WeatherStatus.freezingFog, result)
        
        // Fog
        result = performer.convertWeatherStatus("Brouillard")
        XCTAssertEqual(WeatherStatus.fog, result)
        result = performer.convertWeatherStatus("Fog")
        XCTAssertEqual(WeatherStatus.fog, result)
        
        // Haze
        result = performer.convertWeatherStatus("Brume sèche")
        XCTAssertEqual(WeatherStatus.haze, result)
        result = performer.convertWeatherStatus("Haze")
        XCTAssertEqual(WeatherStatus.haze, result)
        
        // SnowAtTimesHeavyMixedWithRain
        result = performer.convertWeatherStatus("Neige parfois forte mêlée de pluie")
        XCTAssertEqual(WeatherStatus.snowAtTimesHeavyMixedWithRain, result)
        result = performer.convertWeatherStatus("Snow at times heavy mixed with rain")
        XCTAssertEqual(WeatherStatus.snowAtTimesHeavyMixedWithRain, result)
        
        // PeriodsOfSnowMixedWithRain
        result = performer.convertWeatherStatus("Neige intermittente mêlée de pluie")
        XCTAssertEqual(WeatherStatus.periodsOfSnowMixedWithRain, result)
        result = performer.convertWeatherStatus("Periods of snow mixed with rain")
        XCTAssertEqual(WeatherStatus.periodsOfSnowMixedWithRain, result)

        // RainOrDrizzle
        result = performer.convertWeatherStatus("Pluie ou bruine")
        XCTAssertEqual(WeatherStatus.rainOrDrizzle, result)
        result = performer.convertWeatherStatus("Rain or drizzle")
        XCTAssertEqual(WeatherStatus.rainOrDrizzle, result)
        
        // PeriodsOfDrizzleOrRain
        result = performer.convertWeatherStatus("Bruine intermittente ou pluie")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzleOrRain, result)
        result = performer.convertWeatherStatus("Periods of drizzle or rain")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzleOrRain, result)
        
        // LightDrizzleAndFog
        result = performer.convertWeatherStatus("Bruine faible et brouillard")
        XCTAssertEqual(WeatherStatus.lightDrizzleAndFog, result)
        result = performer.convertWeatherStatus("Light drizzle and fog")
        XCTAssertEqual(WeatherStatus.lightDrizzleAndFog, result)
        
        // LightRainAndFog
        result = performer.convertWeatherStatus("Pluie faible et brouillard")
        XCTAssertEqual(WeatherStatus.lightRainAndFog, result)
        result = performer.convertWeatherStatus("Light rain and fog")
        XCTAssertEqual(WeatherStatus.lightRainAndFog, result)
        
        // PeriodsOfDrizzleMixedWithRain
        result = performer.convertWeatherStatus("Bruine intermittente mêlée de pluie")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzleMixedWithRain, result)
        result = performer.convertWeatherStatus("Periods of drizzle mixed with rain")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzleMixedWithRain, result)
        
        // PeriodsOfSnowMixedWithFreezingRain
        result = performer.convertWeatherStatus("Neige intermittente mêlée de pluie verglaçante")
        XCTAssertEqual(WeatherStatus.periodsOfSnowMixedWithFreezingRain, result)
        result = performer.convertWeatherStatus("Periods of snow mixed with freezing rain")
        XCTAssertEqual(WeatherStatus.periodsOfSnowMixedWithFreezingRain, result)
        
        // FogPatches
        result = performer.convertWeatherStatus("Bancs de brouillard")
        XCTAssertEqual(WeatherStatus.fogPatches, result)
        result = performer.convertWeatherStatus("Fog patches")
        XCTAssertEqual(WeatherStatus.fogPatches, result)
        
        // RainMixedWithSnow
        result = performer.convertWeatherStatus("Pluie mêlée de neige")
        XCTAssertEqual(WeatherStatus.rainMixedWithSnow, result)
        result = performer.convertWeatherStatus("Rain mixed with snow")
        XCTAssertEqual(WeatherStatus.rainMixedWithSnow, result)
        
        // SnowMixedWithIcePellets
        result = performer.convertWeatherStatus("Neige mêlée de grésil")
        XCTAssertEqual(WeatherStatus.snowMixedWithIcePellets, result)
        result = performer.convertWeatherStatus("Snow mixed with ice pellets")
        XCTAssertEqual(WeatherStatus.snowMixedWithIcePellets, result)
        
        // PeriodsOfLightSnowMixedWithFreezingDrizzle
        result = performer.convertWeatherStatus("Faible neige intermittente mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.periodsOfLightSnowMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of light snow mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.periodsOfLightSnowMixedWithFreezingDrizzle, result)
        
        // Smoke
        result = performer.convertWeatherStatus("Fumée")
        XCTAssertEqual(WeatherStatus.smoke, result)
        result = performer.convertWeatherStatus("Smoke")
        XCTAssertEqual(WeatherStatus.smoke, result)

        // SnowMixedWithFreezingDrizzle
        result = performer.convertWeatherStatus("Neige mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.snowMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Snow mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.snowMixedWithFreezingDrizzle, result)
        
        // PeriodsOfFreezingDrizzleOrDrizzle
        result = performer.convertWeatherStatus("Bruine verglaçante intermittente ou bruine")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingDrizzleOrDrizzle, result)
        result = performer.convertWeatherStatus("Periods of freezing drizzle or drizzle")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingDrizzleOrDrizzle, result)
        
        // ChanceOfDrizzleOrRain
        result = performer.convertWeatherStatus("Possibilité de bruine ou pluie")
        XCTAssertEqual(WeatherStatus.chanceOfDrizzleOrRain, result)
        result = performer.convertWeatherStatus("Chance of drizzle or rain")
        XCTAssertEqual(WeatherStatus.chanceOfDrizzleOrRain, result)
        
        // ChanceOfWetFlurries
        result = performer.convertWeatherStatus("Possibilité d'averses de neige fondante")
        XCTAssertEqual(WeatherStatus.chanceOfWetFlurries, result)
        result = performer.convertWeatherStatus("Chance of wet flurries")
        XCTAssertEqual(WeatherStatus.chanceOfWetFlurries, result)
        
        // PeriodsOfFreezingDrizzleOrRain
        result = performer.convertWeatherStatus("Bruine verglaçante intermittente ou pluie")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingDrizzleOrRain, result)
        result = performer.convertWeatherStatus("Periods of freezing drizzle or rain")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingDrizzleOrRain, result)
        
        // PeriodsOfFreezingDrizzle
        result = performer.convertWeatherStatus("Bruine verglaçante intermittente")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of freezing drizzle")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingDrizzle, result)
        
        // PeriodsOfFreezingRainOrSnow
        result = performer.convertWeatherStatus("Pluie verglaçante intermittente ou neige")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingRainOrSnow, result)
        result = performer.convertWeatherStatus("Periods of freezing rain or snow")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingRainOrSnow, result)
        
        // FreezingRainMixedWithIcePellets
        result = performer.convertWeatherStatus("Pluie verglaçante mêlée de grésil")
        XCTAssertEqual(WeatherStatus.freezingRainMixedWithIcePellets, result)
        result = performer.convertWeatherStatus("Freezing rain mixed with ice pellets")
        XCTAssertEqual(WeatherStatus.freezingRainMixedWithIcePellets, result)
        
        // PeriodsOfFreezingRainMixedWithIcePellets
        result = performer.convertWeatherStatus("Pluie verglaçante intermittente mêlée de grésil")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingRainMixedWithIcePellets, result)
        result = performer.convertWeatherStatus("Periods of freezing rain mixed with ice pellets")
        XCTAssertEqual(WeatherStatus.periodsOfFreezingRainMixedWithIcePellets, result)
        
        // ChanceOfShowersOrThunderstorms
        result = performer.convertWeatherStatus("Possibilité d'averses ou orages")
        XCTAssertEqual(WeatherStatus.chanceOfShowersOrThunderstorms, result)
        result = performer.convertWeatherStatus("Chance of showers or thunderstorms")
        XCTAssertEqual(WeatherStatus.chanceOfShowersOrThunderstorms, result)
        result = performer.convertWeatherStatus("Chance of showers or thundershowers")
        XCTAssertEqual(WeatherStatus.chanceOfShowersOrThunderstorms, result)
        
        // ChanceOfWetFlurriesOrRainShowers
        result = performer.convertWeatherStatus("Possibilité d'averses de neige fondante ou de pluie")
        XCTAssertEqual(WeatherStatus.chanceOfWetFlurriesOrRainShowers, result)
        result = performer.convertWeatherStatus("Chance of wet flurries or rain showers")
        XCTAssertEqual(WeatherStatus.chanceOfWetFlurriesOrRainShowers, result)
        
        // ChanceOfRain
        result = performer.convertWeatherStatus("Possibilité de pluie")
        XCTAssertEqual(WeatherStatus.chanceOfRain, result)
        result = performer.convertWeatherStatus("Chance of rain")
        XCTAssertEqual(WeatherStatus.chanceOfRain, result)
        
        // LightWetSnow
        result = performer.convertWeatherStatus("Faible neige fondante")
        XCTAssertEqual(WeatherStatus.lightWetSnow, result)
        result = performer.convertWeatherStatus("Light wet snow")
        XCTAssertEqual(WeatherStatus.lightWetSnow, result)
        
        // Precipitation
        result = performer.convertWeatherStatus("Précipitations")
        XCTAssertEqual(WeatherStatus.precipitation, result)
        result = performer.convertWeatherStatus("Precipitation")
        XCTAssertEqual(WeatherStatus.precipitation, result)
        
        // DrizzleOrRain
        result = performer.convertWeatherStatus("Bruine ou pluie")
        XCTAssertEqual(WeatherStatus.drizzleOrRain, result)
        result = performer.convertWeatherStatus("Drizzle or rain")
        XCTAssertEqual(WeatherStatus.drizzleOrRain, result)
        
        // FreezingRainMixedWithSnow
        result = performer.convertWeatherStatus("Pluie verglaçante mêlée de neige")
        XCTAssertEqual(WeatherStatus.freezingRainMixedWithSnow, result)
        result = performer.convertWeatherStatus("Freezing rain mixed with snow")
        XCTAssertEqual(WeatherStatus.freezingRainMixedWithSnow, result)
        
        // FreezingDrizzleOrRain
        result = performer.convertWeatherStatus("Bruine verglaçante ou pluie")
        XCTAssertEqual(WeatherStatus.freezingDrizzleOrRain, result)
        result = performer.convertWeatherStatus("Freezing drizzle or rain")
        XCTAssertEqual(WeatherStatus.freezingDrizzleOrRain, result)
        
        // RainAtTimesHeavyOrDrizzle
        result = performer.convertWeatherStatus("Pluie parfois forte ou bruine")
        XCTAssertEqual(WeatherStatus.rainAtTimesHeavyOrDrizzle, result)
        result = performer.convertWeatherStatus("Rain at times heavy or drizzle")
        XCTAssertEqual(WeatherStatus.rainAtTimesHeavyOrDrizzle, result)
        
        // PeriodsOfLightSnowMixedWithRain
        result = performer.convertWeatherStatus("Faible neige intermittente mêlée de pluie")
        XCTAssertEqual(WeatherStatus.periodsOfLightSnowMixedWithRain, result)
        result = performer.convertWeatherStatus("Periods of light snow mixed with rain")
        XCTAssertEqual(WeatherStatus.periodsOfLightSnowMixedWithRain, result)
        
        // AFewShowersOrDrizzle
        result = performer.convertWeatherStatus("Quelques averses ou bruine")
        XCTAssertEqual(WeatherStatus.aFewShowersOrDrizzle, result)
        result = performer.convertWeatherStatus("A few showers or drizzle")
        XCTAssertEqual(WeatherStatus.aFewShowersOrDrizzle, result)
        
        // PeriodsOfWetSnowOrRain
        result = performer.convertWeatherStatus("Neige fondante intermittente ou pluie")
        XCTAssertEqual(WeatherStatus.periodsOfWetSnowOrRain, result)
        result = performer.convertWeatherStatus("Periods of wet snow or rain")
        XCTAssertEqual(WeatherStatus.periodsOfWetSnowOrRain, result)
        
        // LightSnowMixedWithRain
        result = performer.convertWeatherStatus("Faible neige mêlée de pluie")
        XCTAssertEqual(WeatherStatus.lightSnowMixedWithRain, result)
        result = performer.convertWeatherStatus("Light snow mixed with rain")
        XCTAssertEqual(WeatherStatus.lightSnowMixedWithRain, result)

        // PeriodsOfDrizzleOrFreezingDrizzle
        result = performer.convertWeatherStatus("Bruine intermittente ou bruine verglaçante")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzleOrFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of drizzle or freezing drizzle")
        XCTAssertEqual(WeatherStatus.periodsOfDrizzleOrFreezingDrizzle, result)
        
        // PeriodsOfWetSnow
        result = performer.convertWeatherStatus("Neige fondante intermittente")
        XCTAssertEqual(WeatherStatus.periodsOfWetSnow, result)
        result = performer.convertWeatherStatus("Periods of wet snow")
        XCTAssertEqual(WeatherStatus.periodsOfWetSnow, result)

        // PeriodsOfSnowOrFreezingDrizzle
        result = performer.convertWeatherStatus("Neige intermittente ou bruine verglaçante")
        XCTAssertEqual(WeatherStatus.periodsOfSnowOrFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of snow or freezing drizzle")
        XCTAssertEqual(WeatherStatus.periodsOfSnowOrFreezingDrizzle, result)
        
        // ChanceOfFreezingDrizzle
        result = performer.convertWeatherStatus("Possibilité de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.chanceOfFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Chance of freezing drizzle")
        XCTAssertEqual(WeatherStatus.chanceOfFreezingDrizzle, result)
        
        // FreezingDrizzle
        result = performer.convertWeatherStatus("Bruine verglaçante")
        XCTAssertEqual(WeatherStatus.freezingDrizzle, result)
        result = performer.convertWeatherStatus("Freezing drizzle")
        XCTAssertEqual(WeatherStatus.freezingDrizzle, result)
        
        // PeriodsOfSnowMixedWithFreezingDrizzle
        result = performer.convertWeatherStatus("Neige intermittente mêlée de bruine verglaçante")
        XCTAssertEqual(WeatherStatus.periodsOfSnowMixedWithFreezingDrizzle, result)
        result = performer.convertWeatherStatus("Periods of snow mixed with freezing drizzle")
        XCTAssertEqual(WeatherStatus.periodsOfSnowMixedWithFreezingDrizzle, result)
        
        // LightSnowOrRain
        result = performer.convertWeatherStatus("Faible neige ou pluie")
        XCTAssertEqual(WeatherStatus.lightSnowOrRain, result)
        result = performer.convertWeatherStatus("Light snow or rain")
        XCTAssertEqual(WeatherStatus.lightSnowOrRain, result)
        
        // FreezingRain
        result = performer.convertWeatherStatus("Pluie verglaçante")
        XCTAssertEqual(WeatherStatus.freezingRain, result)
        result = performer.convertWeatherStatus("Freezing rain")
        XCTAssertEqual(WeatherStatus.freezingRain, result)
        
        // SnowOrFreezingRain
        result = performer.convertWeatherStatus("Neige ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.snowOrFreezingRain, result)
        result = performer.convertWeatherStatus("Snow or freezing rain")
        XCTAssertEqual(WeatherStatus.snowOrFreezingRain, result)

        // HeavyRainshower
        result = performer.convertWeatherStatus("Forte averse de pluie")
        XCTAssertEqual(WeatherStatus.heavyRainshower, result)
        result = performer.convertWeatherStatus("Heavy rainshower")
        XCTAssertEqual(WeatherStatus.heavyRainshower, result)
        
        // AFewShowersOrThunderstorms
        result = performer.convertWeatherStatus("Quelques averses ou orages")
        XCTAssertEqual(WeatherStatus.aFewShowersOrThunderstorms, result)
        result = performer.convertWeatherStatus("A few showers or thunderstorms")
        XCTAssertEqual(WeatherStatus.aFewShowersOrThunderstorms, result)
        result = performer.convertWeatherStatus("A few showers or thundershowers")
        XCTAssertEqual(WeatherStatus.aFewShowersOrThunderstorms, result)
        
        // Thunderstorm
        result = performer.convertWeatherStatus("Orage")
        XCTAssertEqual(WeatherStatus.thunderstorm, result)
        result = performer.convertWeatherStatus("Thunderstorm")
        XCTAssertEqual(WeatherStatus.thunderstorm, result)
        
        // ThunderstormWithLightRainshowers
        result = performer.convertWeatherStatus("Orage avec averse de pluie")
        XCTAssertEqual(WeatherStatus.thunderstormWithLightRainshowers, result)
        result = performer.convertWeatherStatus("Thunderstorm with light rainshowers")
        XCTAssertEqual(WeatherStatus.thunderstormWithLightRainshowers, result)
        
        // SnowOrIcePellets
        result = performer.convertWeatherStatus("Neige ou grésil")
        XCTAssertEqual(WeatherStatus.snowOrIcePellets, result)
        result = performer.convertWeatherStatus("Snow or ice pellets")
        XCTAssertEqual(WeatherStatus.snowOrIcePellets, result)
        
        // IcePelletsOrSnow
        result = performer.convertWeatherStatus("Grésil ou neige")
        XCTAssertEqual(WeatherStatus.icePelletsOrSnow, result)
        result = performer.convertWeatherStatus("Ice pellets or snow")
        XCTAssertEqual(WeatherStatus.icePelletsOrSnow, result)
        
        // WetFlurriesOrRainShowers
        result = performer.convertWeatherStatus("Averses de neige fondante ou de pluie")
        XCTAssertEqual(WeatherStatus.wetFlurriesOrRainShowers, result)
        result = performer.convertWeatherStatus("Wet flurries or rain showers")
        XCTAssertEqual(WeatherStatus.wetFlurriesOrRainShowers, result)
        
        // LightSnowOrFreezingRain
        result = performer.convertWeatherStatus("Faible neige ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.lightSnowOrFreezingRain, result)
        result = performer.convertWeatherStatus("Light snow or freezing rain")
        XCTAssertEqual(WeatherStatus.lightSnowOrFreezingRain, result)
        
        // RainAtTimesHeavyOrSnow
        result = performer.convertWeatherStatus("Pluie parfois forte ou neige")
        XCTAssertEqual(WeatherStatus.rainAtTimesHeavyOrSnow, result)
        result = performer.convertWeatherStatus("Rain at times heavy or snow")
        XCTAssertEqual(WeatherStatus.rainAtTimesHeavyOrSnow, result)
        
        // SnowAtTimesHeavyOrRain
        result = performer.convertWeatherStatus("Neige parfois forte ou pluie")
        XCTAssertEqual(WeatherStatus.snowAtTimesHeavyOrRain, result)
        result = performer.convertWeatherStatus("Snow at times heavy or rain")
        XCTAssertEqual(WeatherStatus.snowAtTimesHeavyOrRain, result)
        
        // FogDissipating
        result = performer.convertWeatherStatus("Brouillard se dissipant")
        XCTAssertEqual(WeatherStatus.fogDissipating, result)
        result = performer.convertWeatherStatus("Fog dissipating")
        XCTAssertEqual(WeatherStatus.fogDissipating, result)
        
        // ShowersOrThunderstorms
        result = performer.convertWeatherStatus("Averses ou orages")
        XCTAssertEqual(WeatherStatus.showersOrThunderstorms, result)
        result = performer.convertWeatherStatus("Showers or thunderstorms")
        XCTAssertEqual(WeatherStatus.showersOrThunderstorms, result)
        result = performer.convertWeatherStatus("Showers or thundershowers")
        XCTAssertEqual(WeatherStatus.showersOrThunderstorms, result)
        
        // ThunderstormWithLightRain
        result = performer.convertWeatherStatus("Orage avec faible pluie")
        XCTAssertEqual(WeatherStatus.thunderstormWithLightRain, result)
        result = performer.convertWeatherStatus("Thunderstorm with light rain")
        XCTAssertEqual(WeatherStatus.thunderstormWithLightRain, result)
        
        // ChanceOfRainOrDrizzle
        result = performer.convertWeatherStatus("Possibilité de pluie ou bruine")
        XCTAssertEqual(WeatherStatus.chanceOfRainOrDrizzle, result)
        result = performer.convertWeatherStatus("Chance of rain or drizzle")
        XCTAssertEqual(WeatherStatus.chanceOfRainOrDrizzle, result)
        
        // ChanceOfSnowMixedWithRain
        result = performer.convertWeatherStatus("Possibilité de neige mêlée de pluie")
        XCTAssertEqual(WeatherStatus.chanceOfSnowMixedWithRain, result)
        result = performer.convertWeatherStatus("Chance of snow mixed with rain")
        XCTAssertEqual(WeatherStatus.chanceOfSnowMixedWithRain, result)
        
        // ChanceOfSnowOrRain
        result = performer.convertWeatherStatus("Possibilité de neige ou pluie")
        XCTAssertEqual(WeatherStatus.chanceOfSnowOrRain, result)
        result = performer.convertWeatherStatus("Chance of snow or rain")
        XCTAssertEqual(WeatherStatus.chanceOfSnowOrRain, result)
        
        // ChanceOfShowersAtTimesHeavy
        result = performer.convertWeatherStatus("Possibilité d'averses parfois fortes")
        XCTAssertEqual(WeatherStatus.chanceOfShowersAtTimesHeavy, result)
        result = performer.convertWeatherStatus("Chance of showers at times heavy")
        XCTAssertEqual(WeatherStatus.chanceOfShowersAtTimesHeavy, result)
        
        // ShowersAtTimesHeavy
        result = performer.convertWeatherStatus("Averses parfois fortes")
        XCTAssertEqual(WeatherStatus.showersAtTimesHeavy, result)
        result = performer.convertWeatherStatus("Showers at times heavy")
        XCTAssertEqual(WeatherStatus.showersAtTimesHeavy, result)
        
        // ChanceOfThunderstorms
        result = performer.convertWeatherStatus("Possibilité d'orages")
        XCTAssertEqual(WeatherStatus.chanceOfThunderstorms, result)
        result = performer.convertWeatherStatus("Chance of thunderstorms")
        XCTAssertEqual(WeatherStatus.chanceOfThunderstorms, result)
        
        // ShowersAtTimesHeavyOrThundershowers
        result = performer.convertWeatherStatus("Averses parfois fortes ou orages")
        XCTAssertEqual(WeatherStatus.showersAtTimesHeavyOrThundershowers, result)
        result = performer.convertWeatherStatus("Showers at times heavy or thundershowers")
        XCTAssertEqual(WeatherStatus.showersAtTimesHeavyOrThundershowers, result)
        
        // icePelletsMixedWithSnow
        result = performer.convertWeatherStatus("Grésil mêlé de neige")
        XCTAssertEqual(WeatherStatus.icePelletsMixedWithSnow, result)
        result = performer.convertWeatherStatus("Ice pellets mixed with snow")
        XCTAssertEqual(WeatherStatus.icePelletsMixedWithSnow, result)
        
        // snowAtTimesHeavyMixedWithIcePellets
        result = performer.convertWeatherStatus("Neige parfois forte mêlée de grésil")
        XCTAssertEqual(WeatherStatus.snowAtTimesHeavyMixedWithIcePellets, result)
        result = performer.convertWeatherStatus("Snow at times heavy mixed with ice pellets")
        XCTAssertEqual(WeatherStatus.snowAtTimesHeavyMixedWithIcePellets, result)
        
        // freezingRainOrRain
        result = performer.convertWeatherStatus("Pluie verglaçante ou pluie")
        XCTAssertEqual(WeatherStatus.freezingRainOrRain, result)
        result = performer.convertWeatherStatus("Freezing rain or rain")
        XCTAssertEqual(WeatherStatus.freezingRainOrRain, result)
        
        // chanceOfFreezingRain
        result = performer.convertWeatherStatus("Possibilité de pluie verglaçante")
        XCTAssertEqual(WeatherStatus.chanceOfFreezingRain, result)
        result = performer.convertWeatherStatus("Chance of freezing rain")
        XCTAssertEqual(WeatherStatus.chanceOfFreezingRain, result)
    
        // periodsOfSnowMixedWithIcePellets
        result = performer.convertWeatherStatus("Neige intermittente mêlée de grésil")
        XCTAssertEqual(WeatherStatus.periodsOfSnowMixedWithIcePellets, result)
        result = performer.convertWeatherStatus("Periods of snow mixed with ice pellets")
        XCTAssertEqual(WeatherStatus.periodsOfSnowMixedWithIcePellets, result)
        
        // periodsOfSnowMixedWithIcePellets
        result = performer.convertWeatherStatus("Pluie parfois forte ou pluie verglaçante")
        XCTAssertEqual(WeatherStatus.rainAtTimesHeavyOrFreezingRain, result)
        result = performer.convertWeatherStatus("Rain at times heavy or freezing rain")
        XCTAssertEqual(WeatherStatus.rainAtTimesHeavyOrFreezingRain, result)
        
        // icePelletsMixedWithFreezingRain
        result = performer.convertWeatherStatus("Grésil mêlé de pluie verglaçante")
        XCTAssertEqual(WeatherStatus.icePelletsMixedWithFreezingRain, result)
        result = performer.convertWeatherStatus("Ice pellets mixed with freezing rain")
        XCTAssertEqual(WeatherStatus.icePelletsMixedWithFreezingRain, result)
        
        // freezingRainOrIcePellets
        result = performer.convertWeatherStatus("Pluie verglaçante ou grésil")
        XCTAssertEqual(WeatherStatus.freezingRainOrIcePellets, result)
        result = performer.convertWeatherStatus("Freezing rain or ice pellets")
        XCTAssertEqual(WeatherStatus.freezingRainOrIcePellets, result)
        
        // icePellets
        result = performer.convertWeatherStatus("Grésil")
        XCTAssertEqual(WeatherStatus.icePellets, result)
        result = performer.convertWeatherStatus("Ice Pellets")
        XCTAssertEqual(WeatherStatus.icePellets, result)
        
        // rainMixedWithFreezingRain
        result = performer.convertWeatherStatus("Pluie mêlée de pluie verglaçante")
        XCTAssertEqual(WeatherStatus.rainMixedWithFreezingRain, result)
        result = performer.convertWeatherStatus("Rain mixed with freezing rain")
        XCTAssertEqual(WeatherStatus.rainMixedWithFreezingRain, result)
        
        // lightRainAndDrizzle
        result = performer.convertWeatherStatus("Pluie et bruine faibles")
        XCTAssertEqual(WeatherStatus.lightRainAndDrizzle, result)
        result = performer.convertWeatherStatus("Light Rain and Drizzle")
        XCTAssertEqual(WeatherStatus.lightRainAndDrizzle, result)
        
        // lightSnowShowerAndBlowingSnow
        result = performer.convertWeatherStatus("Faible averse de neige et poudrerie élevée")
        XCTAssertEqual(WeatherStatus.lightSnowShowerAndBlowingSnow, result)
        result = performer.convertWeatherStatus("Light Snow Shower and Blowing Snow")
        XCTAssertEqual(WeatherStatus.lightSnowShowerAndBlowingSnow, result)
        
        // aFewRainShowersOrWetFlurries
        result = performer.convertWeatherStatus("A few rain showers or wet flurries")
        XCTAssertEqual(WeatherStatus.aFewRainShowersOrWetFlurries, result)
        
        // rainShower
        result = performer.convertWeatherStatus("Averse de pluie")
        XCTAssertEqual(WeatherStatus.rainShower, result)
        result = performer.convertWeatherStatus("Rainshower")
        XCTAssertEqual(WeatherStatus.rainShower, result)
        
        // chanceOfSnowAtTimesHeavy
        result = performer.convertWeatherStatus("Possibilité de neige parfois forte")
        XCTAssertEqual(WeatherStatus.chanceOfSnowAtTimesHeavy, result)
        result = performer.convertWeatherStatus("Chance of snow at times heavy")
        XCTAssertEqual(WeatherStatus.chanceOfSnowAtTimesHeavy, result)
        
        
        
        
        // Cloudy with X percent chance of flurries
        // Juste un cas pour convertWeatherStatusWithRegex
        result = performer.convertWeatherStatus("Nuageux avec 60 pour cent de probabilité d'averses de neige")
        XCTAssertEqual(WeatherStatus.cloudyWithXPercentChanceOfFlurries, result)
        result = performer.convertWeatherStatus("Cloudy with 60 percent chance of flurries")
        XCTAssertEqual(WeatherStatus.cloudyWithXPercentChanceOfFlurries, result)
        
        // No info
        result = performer.convertWeatherStatus("")
        XCTAssertEqual(WeatherStatus.na, result)
        
        // NA
        result = performer.convertWeatherStatus("test")
        XCTAssertEqual(WeatherStatus.na, result)
    }
    
    func testConvertWeatherStatusWithRegex() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        
        // PartCloudy
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.convertWeatherStatusWithRegex("Nuageux avec 60 pour cent de probabilité d'averses de neige")
        XCTAssertEqual(WeatherStatus.cloudyWithXPercentChanceOfFlurries, result)
        result = performer.convertWeatherStatusWithRegex("Cloudy with 60 percent chance of flurries")
        XCTAssertEqual(WeatherStatus.cloudyWithXPercentChanceOfFlurries, result)
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
        
        result = performer.extractWeatherConditionNowFromTitle("Current Conditions: Ice Pellets, 0.4&#xB0;C")
        XCTAssertEqual("Ice Pellets", result)
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
        
        result = performer.extractTemperature("Vendredi soir et nuit: Averses de neige. Températures à la hausse pour atteindre moins 1 en soirée puis à la baisse.")
        XCTAssertEqual("moins 1", result)
        
        result = performer.extractTemperature("Friday night: Flurries. Temperature rising to minus 1 in the evening then falling.")
        XCTAssertEqual("minus 1", result)
        
        result = performer.extractTemperature("Mercredi: Possibilité d'averses de neige. Températures à la baisse pour atteindre moins 7 ce matin puis stables. PdP 40%")
        XCTAssertEqual("moins 7", result)
        
        result = performer.extractTemperature("Wednesday: Chance of flurries. Temperature falling to minus 7 this morning then steady. POP 40%")
        XCTAssertEqual("minus 7", result)
        
        result = performer.extractTemperature("Samedi: Possibilité d'averses de neige. Températures à la baisse pour atteindre moins 2 le matin puis stables. PdP 60%")
        XCTAssertEqual("moins 2", result)
        
        result = performer.extractTemperature("Saturday: Chance of rain showers or flurries. Temperature falling to zero in the morning then rising. POP 60%")
        XCTAssertEqual("zero", result)
        
        result = performer.extractTemperature("Saturday: Chance of showers. Temperature falling to plus 3 in the morning then steady. POP 60%")
        XCTAssertEqual("plus 3", result)
        
        result = performer.extractTemperature("Samedi: Possibilité d'averses de pluie ou de neige. Températures à la baisse pour atteindre zéro le matin puis à la hausse. PdP 60%")
        XCTAssertEqual("zéro", result)
        
        result = performer.extractTemperature("Ce soir et cette nuit: Pluie ou neige. Températures à la hausse pour atteindre plus 3 ce soir puis à la baisse.")
        XCTAssertEqual("plus 3", result)
        
        result = performer.extractTemperature("Friday night: Rain or snow. Temperature rising to plus 3 this evening then falling.")
        XCTAssertEqual("plus 3", result)
        
        result = performer.extractTemperature("Vendredi soir: Quelques averses débutant après minuit. Températures à la hausse pour atteindre plus 5 ce soir puis stable.")
        XCTAssertEqual("plus 5", result)
        
        result = performer.extractTemperature("Friday night: Rain or snow. Temperature rising to plus 5 this evening then steady.")
        XCTAssertEqual("plus 5", result)
    }
    
    func testConvertWeatherDay() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        
        // Conditions actuelles
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        var result = performer.convertWeatherDay("Conditions actuelles", currentDay: 0)
        XCTAssertEqual(WeatherDay.now, result)
        result = performer.convertWeatherDay("Current Conditions", currentDay: 0)
        XCTAssertEqual(WeatherDay.now, result)
        result = performer.convertWeatherDay("Conditions actuelles", currentDay: 3)
        XCTAssertEqual(WeatherDay.now, result)
        
        // Prévisions météo
        result = performer.convertWeatherDay("Prévisions météo", currentDay: 0)
        XCTAssertEqual(WeatherDay.today, result)
        result = performer.convertWeatherDay("Weather Forecasts", currentDay: 0)
        XCTAssertEqual(WeatherDay.today, result)
        result = performer.convertWeatherDay("Prévisions météo", currentDay: 1)
        XCTAssertEqual(WeatherDay.tomorow, result)
        result = performer.convertWeatherDay("Prévisions météo", currentDay: 2)
        XCTAssertEqual(WeatherDay.day2, result)
        
        // Invalid data
        result = performer.convertWeatherDay("test", currentDay: 0)
        XCTAssertEqual(WeatherDay.na, result)
        result = performer.convertWeatherDay("Prévisions météo", currentDay: 162)
        XCTAssertEqual(WeatherDay.na, result)
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
        XCTAssertEqual(Tendency.minimum, result)
        
        result = performer.extractTendency(titleLowEn)
        XCTAssertEqual(Tendency.minimum, result)
        
        result = performer.extractTendency(titleHighFr)
        XCTAssertEqual(Tendency.maximum, result)
        
        result = performer.extractTendency(titleHighEn)
        XCTAssertEqual(Tendency.maximum, result)
        
        result = performer.extractTendency("Ce soir et cette nuit: Pluie parfois forte. Températures stables près de plus 3.")
        XCTAssertEqual(Tendency.steady, result)
        
        result = performer.extractTendency("Thursday night: Rain at times heavy. Temperature steady near plus 3")
        XCTAssertEqual(Tendency.steady, result)
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
        
        result = performer.isAlert(alertThunderFr)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertThunderEn)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertThunderWatchFr)
        XCTAssertTrue(result)
        
        result = performer.isAlert(alertThunderWatchEn)
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
        
        result = performer.extractAlertText(alertThunderWatchFr)
        XCTAssertEqual("VEILLE D'ORAGES VIOLENTS EN VIGUEUR", result)
        
        result = performer.extractAlertText(alertThunderWatchEn)
        XCTAssertEqual("SEVERE THUNDERSTORM WATCH IN EFFECT", result)
        
        result = performer.extractAlertText(alertThunderFr)
        XCTAssertEqual("ALERTE D'ORAGES VIOLENTS EN VIGUEUR", result)
        
        result = performer.extractAlertText(alertThunderEn)
        XCTAssertEqual("SEVERE THUNDERSTORM WARNING IN EFFECT", result)
        
        result = performer.extractAlertText(alertTitleFr)
        XCTAssertEqual("", result)
        
        result = performer.extractAlertText(alertTitleEn)
        XCTAssertEqual("", result)
        
        result = performer.extractAlertText(" IN EFFECT, Bonaventure")
        XCTAssertEqual("", result)
    }
    
    func testExtractAlertType() {
        let parser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        let rssEntry = RssEntry(parent: parser as RssParser)
        let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
        
        var result = performer.extractAlertType("AVIS DE BROUILLARD TERMINÉ")
        XCTAssertEqual(AlertType.ended, result)
        
        result = performer.extractAlertType("FOG ADVISORY ENDED")
        XCTAssertEqual(AlertType.ended, result)
        
        result = performer.extractAlertType("FROST ADVISORY IN EFFECT")
        XCTAssertEqual(AlertType.warning, result)
        
        result = performer.extractAlertType("test")
        XCTAssertEqual(AlertType.warning, result)
    }
}
