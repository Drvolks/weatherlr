//
//  RssEntryToWeatherInformation.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-05.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class RssEntryToWeatherInformation {
    var rssEntries:[RssEntry]
    
    init(rssEntries: [RssEntry]) {
        self.rssEntries = rssEntries
    }
    
    init(rssEntry: RssEntry) {
        self.rssEntries = [RssEntry]()
        self.rssEntries.append(rssEntry)
    }
    
    func perform() -> [WeatherInformation] {
        var result = [WeatherInformation]()
        
        var debut = 0
        // l'entrée alerte est optionnelle et en plus on la retire si elle ne contient pas d'alerte
        for i in debut..<rssEntries.count {
            if(isAlert(rssEntries[i].title)) {
                debut = i+1
            } else {
                break
            }
        }
        
        for i in debut..<rssEntries.count {
            let weatherInformation = convert(rssEntries[i], position: i-debut)
            result.append(weatherInformation)
        }
        
        return result
    }
    
    func convert(rssEntry: RssEntry, position: Int) -> WeatherInformation {
        let day = convertWeatherDay(rssEntry.category, position: position)
        
        let statusText:String;
        if day == .Now {
            statusText = extractWeatherConditionNowFromTitle(rssEntry.title)
        } else {
            statusText = extractWeatherCondition(rssEntry.title)
        }

        let temperature:Int
        let weatherStatus:WeatherStatus
        if day == .Now {
            let temperatureText = extractTemperatureNowFromTitle(rssEntry.title)
            temperature = convertTemperature(temperatureText)
            
            if statusText == "" {
                weatherStatus = WeatherStatus.Blank
            } else {
                weatherStatus = convertWeatherStatus(statusText)
            }
        } else {
            let temperatureText = extractTemperature(rssEntry.title)
            temperature = convertTemperatureWithTextSign(temperatureText)
            weatherStatus = convertWeatherStatus(statusText)
        }
        
        let detail = nettoyerDetail(rssEntry.summary)
        let tendendy = extractTendency(rssEntry.title)
        let when = extractWhen(rssEntry.title)
        let night = isNight(rssEntry.title)
        
        let result = WeatherInformation(temperature: temperature, weatherStatus: weatherStatus, weatherDay: day, summary: rssEntry.title, detail: detail, tendancy: tendendy, when: when, night: night)
        return result
    }
    
    func convertAlert(rssEntry: RssEntry) -> AlertInformation? {
        let alertText = extractAlertText(rssEntry.title)
        if !alertText.isEmpty {
            let alert = AlertInformation(alertText: alertText, url: rssEntry.link)
            return alert
        }
        
        return nil
    }
    
    func convertWeatherStatus(text: String) -> WeatherStatus {
        switch text.lowercaseString {
        case "partiellement nuageux", "partly cloudy":
            return WeatherStatus.PartlyCloudy
        case "généralement ensoleillé", "mainly sunny":
            return WeatherStatus.MainlySunny
        case "dégagé", "clear":
            return WeatherStatus.Clear
        case "faible neige", "neige faible", "light snow":
            return WeatherStatus.LightSnow
        case "neige ou pluie", "snow or rain", "pluie ou neige", "rain or snow":
            return WeatherStatus.SnowOrRain
        case "pluie intermittente", "periods of rain":
            return WeatherStatus.PeriodsOfRain
        case "possibilité d'averses de pluie ou de neige", "chance of rain showers or flurries", "possibilité d'averses de neige ou de pluie", "chance of flurries or rain showers":
            return WeatherStatus.ChanceOfRainShowersOrFlurries
        case "possibilité d'averses de neige", "chance of flurries":
            return WeatherStatus.ChanceOfFlurries
        case "passages nuageux", "cloudy periods":
            return WeatherStatus.CloudyPeriods
        case "ensoleillé", "sunny":
            return WeatherStatus.Sunny
        case "possibilité d'averses", "chance of showers":
            return WeatherStatus.ChanceOfShowers
        case "généralement nuageux", "mostly cloudy", "mainly cloudy":
            return WeatherStatus.MostlyCloudy
        case "nuageux", "cloudy":
            return WeatherStatus.Cloudy
        case "pluie faible", "light rain":
            return WeatherStatus.LightRain
        case "pluie", "rain":
            return WeatherStatus.Rain
        case "averses de pluie ou de neige", "rain showers or flurries":
            return WeatherStatus.RainShowersOrFlurries
        case "pluie intermittente ou neige", "periods of rain or snow":
            return WeatherStatus.PeriodsOfRainOrSnow
        case "neige intermittente", "periods of snow":
            return WeatherStatus.PeriodsOfSnow
        case "quelques averses de pluie ou de neige", "a few rain showers or flurries":
            return WeatherStatus.AFewRainShowersOrFlurries
        case "alternance de soleil et de nuages", "a mix of sun and cloud":
            return WeatherStatus.AMixOfSunAndCloud
        case "pluie parfois forte", "rain at times heavy":
            return WeatherStatus.RainAtTimesHeavy
        case "quelques averses de neige","a few flurries":
            return WeatherStatus.AFewFlurries
        case "quelques nuages","a few clouds":
            return WeatherStatus.AFewClouds
        case "dégagement","clearing":
            return WeatherStatus.Clearing
        case "brume", "mist":
            return WeatherStatus.Mist
        case "faible averse de pluie", "light rainshower":
            return WeatherStatus.LightRainshower
        case "neige", "snow":
            return WeatherStatus.Snow
        case "averses", "showers":
            return WeatherStatus.Showers
        case "quelques averses", "a few showers":
            return WeatherStatus.AFewShowers
        case "averses ou bruine", "showers or drizzle":
            return WeatherStatus.ShowersOrDrizzle
        case "pluie intermittente ou bruine", "periods of rain or drizzle":
            return WeatherStatus.PeriodsOfRainOrDrizzle
        case "ennuagement", "increasing cloudiness":
            return WeatherStatus.IncreasingCloudiness
        case "averses de neige", "flurries":
            return WeatherStatus.Flurries
        case "possibilité de bruine", "chance of drizzle":
            return WeatherStatus.ChanceOfDrizzle
        case "bruine", "drizzle":
            return WeatherStatus.Drizzle
        case "neige intermittente ou pluie", "periods of snow or rain":
            return WeatherStatus.PeriodsOfSnowOrRain
        case "faible bruine verglaçante", "light freezing drizzle":
            return WeatherStatus.LightFreezingDrizzle
        case "pluie verglaçante intermittente", "periods of freezing rain":
            return WeatherStatus.PeriodsOfFreezingRain
        case "pluie intermittente ou pluie verglaçante", "periods of rain or freezing rain":
            return WeatherStatus.PeriodsOfRainOrFreezingRain
        case "bruine intermittente", "periods of drizzle":
            return WeatherStatus.PeriodsOfDrizzle
        case "averses de neige ou de pluie", "flurries or rain showers":
            return WeatherStatus.FlurriesOrRainShowers
        case "faible neige intermittente", "periods of light snow":
            return WeatherStatus.PeriodsOfLightSnow
        case "blizzard":
            return WeatherStatus.Blizzard
        case "neige faible et poudrerie élevée", "light snow and blowing snow":
            return WeatherStatus.LightSnowAndBlowingSnow
        case "poudrerie basse", "drifting snow":
            return WeatherStatus.DriftingSnow
        case "couvert", "overcast":
            return WeatherStatus.Overcast
        case "poudrerie élevée", "poudrerie  élevée", "poudrerie", "blowing snow":
            return WeatherStatus.BlowingSnow
        case "généralement dégagé", "mainly clear":
            return WeatherStatus.MainlyClear
        case "neige intermittente ou pluie verglaçante", "faible neige intermittente ou pluie verglaçante", "periods of light snow or freezing rain", "periods of snow or freezing rain":
            return WeatherStatus.PeriodsOfLightSnowOrFreezingRain
        case "pluie ou pluie verglaçante", "rain or freezing rain":
            return WeatherStatus.RainOrFreezingRain
        case "pluie intermittente mêlée de neige", "periods of rain mixed with snow":
            return WeatherStatus.PeriodsOfRainMixedWithSnow
        case "neige intermittente et poudrerie", "periods of snow and blowing snow":
            return WeatherStatus.PeriodsOfSnowAndBlowingSnow
        case "possibilité d'averses ou bruine", "chance of showers or drizzle":
            return WeatherStatus.ChanceOfShowersOrDrizzle
        case "bruine mêlée de bruine verglaçante", "drizzle mixed with freezing drizzle":
            return WeatherStatus.DrizzleMixedWithFreezingDrizzle
        case "possibilité de bruine mêlée de bruine verglaçante", "chance of drizzle mixed with freezing drizzle":
            return WeatherStatus.ChanceOfDrizzleMixedWithFreezingDrizzle
        case "faible averse de neige", "light snowshower":
            return WeatherStatus.LightSnowshower
        case "bruine intermittente mêlée de bruine verglaçante", "periods of drizzle mixed with freezing drizzle":
            return WeatherStatus.PeriodsOfDrizzleMixedWithFreezingDrizzle
        case "bruine verglaçante ou bruine", "freezing drizzle or drizzle":
            return WeatherStatus.FreezingDrizzleOrDrizzle
        default:
            return convertWeatherStatusWithRegex(text)
        }
    }
    
    func convertWeatherStatusWithRegex(text: String) -> WeatherStatus {
        var regex = try! NSRegularExpression(pattern: "Nuageux avec \\d* pour cent de probabilité d'averses de neige", options: [.CaseInsensitive])
        var match = regex.matchesInString(text, options: [], range: NSMakeRange(0, text.startIndex.distanceTo(text.endIndex)))
        if match.count > 0 {
            return WeatherStatus.CloudyWithXPercentChanceOfFlurries
        }
        
        regex = try! NSRegularExpression(pattern: "Cloudy with \\d* percent chance of flurries", options: [.CaseInsensitive])
        match = regex.matchesInString(text, options: [], range: NSMakeRange(0, text.startIndex.distanceTo(text.endIndex)))
        if match.count > 0 {
            return WeatherStatus.CloudyWithXPercentChanceOfFlurries
        }
        
        return WeatherStatus.NA
    }
    
    func convertWeatherDay(text: String, position: Int) -> WeatherDay {
        switch text {
        case "Conditions actuelles", "Current Conditions":
            return WeatherDay.Now
        case "Prévisions météo", "Weather Forecasts":
            if let day = WeatherDay(rawValue: position) {
                return day
            }
            return WeatherDay.NA
        default:
            return WeatherDay.NA
        }
    }
    
    func performRegex(regex: NSRegularExpression, text: String, index: Int) -> String {
        let results = regex.matchesInString(text, options: [], range: NSMakeRange(0, text.startIndex.distanceTo(text.endIndex)))
        if let result = results.first {
            var condition = (text as NSString).substringWithRange(result.rangeAtIndex(index))
            condition = condition.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            return condition
        }
        
        return ""
    }
    
    
    func extractWeatherConditionNowFromSummary(summary: String) -> String {
        let regex = try! NSRegularExpression(pattern: "<b>Condition:</b>(.*?)<br/>", options: [.CaseInsensitive])
        return performRegex(regex, text: summary, index: 1)
    }
    
    func extractTemperatureNowFromSummary(summary: String) -> String {
        let regex = try! NSRegularExpression(pattern: "<b>(Temperature|Température):</b>(.*?)&deg;", options: [.CaseInsensitive])
        return performRegex(regex, text: summary, index: 2)
    }
    
    func extractWeatherConditionNowFromTitle(title: String) -> String {
        let regex = try! NSRegularExpression(pattern: "^.*?:([^0-9]*?),", options: [.CaseInsensitive])
        return performRegex(regex, text: title, index: 1)
    }
    
    func extractTemperatureNowFromTitle(title: String) -> String {
        let regex = try! NSRegularExpression(pattern: ".*?[,:]? ([-\\d,\\.]*?)(°|&#xB0;)", options: [.CaseInsensitive])
        return performRegex(regex, text: title, index: 1)
    }
    
    func extractWeatherCondition(summary: String) -> String {
        let regex = try! NSRegularExpression(pattern: "^.*?:(.*?)\\.", options: [.CaseInsensitive])
        return performRegex(regex, text: summary, index: 1)
    }
    
    func extractTemperature(summary: String) -> String {
        let regex = try! NSRegularExpression(pattern: ".*?(High|Low|Maximum|Minimum|stables près de|steady near) (.*?)(\\.|with|avec|sauf|except)", options: [.CaseInsensitive])
        return performRegex(regex, text: summary, index: 2)
    }
    
    func convertTemperature(temperature: String) -> Int {
        let data = temperature.stringByReplacingOccurrencesOfString(",", withString: ".")
        
        if data == "zéro" || data == "zero" {
            return 0
        }
        
        if let result = Double(data) {
            return Int(round(result))
        }
        
        return 0
    }
    
    func convertTemperatureWithTextSign(temperature: String) -> Int {
        let text = temperature.lowercaseString
        
        var regex = try! NSRegularExpression(pattern: "^(plus|minus|moins)", options: [.CaseInsensitive])
        let sign = performRegex(regex, text: text, index: 1)
        regex = try! NSRegularExpression(pattern: ".*?([\\d\\.,]*)$", options: [.CaseInsensitive])
        let temp = performRegex(regex, text: text, index: 1)
        
        var tempDouble = convertTemperature(temp)
        
        if sign == "minus" || sign == "moins" {
            tempDouble = tempDouble * -1
        }
        
        return tempDouble
    }
    
    func nettoyerDetail(text: String) -> String {
        let regex = try! NSRegularExpression(pattern: "(Prévisions émises|Forecast issued).*$", options: [.CaseInsensitive])
        let textRegex = NSMutableString(string: text)
        regex.replaceMatchesInString(textRegex, options: .WithTransparentBounds, range: NSMakeRange(0, text.startIndex.distanceTo(text.endIndex)), withTemplate: "")
        let result = textRegex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        return result
    }
    
    func isMaximumTemperature(summary: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "(High|Maximum)", options: [.CaseInsensitive])
        let highLow = performRegex(regex, text: summary, index: 1)
        if !highLow.isEmpty {
            return true
        }
        
        return false
    }
    
    func isNight(title: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "(Ce soir|Soir et nuit|Night)", options: [.CaseInsensitive])
        let night = performRegex(regex, text: title, index: 1)
        if night.isEmpty {
            return false
        }
        
        return true
    }
    
    func extractWhen(title: String) -> String {
        let regex = try! NSRegularExpression(pattern: "^(.*?):", options: [.CaseInsensitive])
        return performRegex(regex, text: title, index: 1)
    }
    
    func extractTendency(title: String) -> Tendency {
        let regex = try! NSRegularExpression(pattern: ".*?(High|Low|Maximum|Minimum|stables|steady)", options: [.CaseInsensitive])
        let tendency = performRegex(regex, text: title, index: 1)
        
        switch tendency {
        case "Maximum", "High":
            return Tendency.Maximum
        case "Minimum", "Low":
            return Tendency.Minimum
        case "stables", "steady":
            return Tendency.Steady
        default:
            return Tendency.NA
        }
    }
    
    func isAlert(title: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: ".*?(Aucune veille ou alerte en vigueur|No watches or warnings in effect|WARNING|AVERTISSEMENT|BULLETIN MÉTÉOROLOGIQUE|WEATHER STATEMENT|BULLETIN SPÉCIAL SUR LA QUALITÉ DE L'AIR|SPECIAL AIR QUALITY STATEMENT).*?", options: [])
        let alert = performRegex(regex, text: title, index: 1)
        if alert.isEmpty {
            return false
        }
        
        return true
    }
    
    func extractAlertText(title: String) -> String {
        var regex = try! NSRegularExpression(pattern: "(WARNING|AVERTISSEMENT|BULLETIN MÉTÉOROLOGIQUE|WEATHER STATEMENT|BULLETIN SPÉCIAL SUR LA QUALITÉ DE L'AIR|SPECIAL AIR QUALITY STATEMENT)", options: [])
        let alert = performRegex(regex, text: title, index: 1)
        if alert.isEmpty {
            return ""
        }

        regex = try! NSRegularExpression(pattern: "^(.*?)(,|$)", options: [])
        return performRegex(regex, text: title, index: 1)
    }
}
