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
        if(rssEntries.count > 0 && isAlert(rssEntries[0].title)) {
            debut = 1
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
        let weatherStatus = convertWeatherStatus(statusText)
        
        let temperature:Int
        if day == .Now {
            let temperatureText = extractTemperatureNowFromTitle(rssEntry.title)
            temperature = convertTemperature(temperatureText)
        } else {
            let temperatureText = extractTemperature(rssEntry.title)
            temperature = convertTemperatureWithTextSign(temperatureText)
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
        switch text {
        case "Partiellement nuageux", "Partly cloudy":
            return WeatherStatus.PartlyCloudy
        case "Généralement ensoleillé", "Mainly Sunny":
            return WeatherStatus.MainlySunny
        case "Dégagé", "Clear":
            return WeatherStatus.Clear
        case "Faible neige", "Neige faible", "Light snow":
            return WeatherStatus.LightSnow
        case "Neige ou pluie", "Snow or rain":
            return WeatherStatus.SnowOrRain
        case "Pluie intermittente", "Periods of rain":
            return WeatherStatus.PeriodsOfRain
        case "Possibilité d'averses de pluie ou de neige", "Chance of rain showers or flurries":
            return WeatherStatus.ChanceOfRainShowersOrFlurries
        case "Possibilité d'averses de neige", "Chance of flurries":
            return WeatherStatus.ChanceOfFlurries
        case "Passages nuageux", "Cloudy periods":
            return WeatherStatus.CloudyPeriods
        case "Ensoleillé", "Sunny":
            return WeatherStatus.Sunny
        case "Possibilité d'averses", "Chance of showers":
            return WeatherStatus.ChanceOfShowers
        case "Généralement nuageux", "Mostly Cloudy":
            return WeatherStatus.MostlyCloudy
        case "Nuageux", "Cloudy":
            return WeatherStatus.Cloudy
        case "Pluie faible", "Light Rain":
            return WeatherStatus.LightRain
        case "Pluie", "Rain":
            return WeatherStatus.Rain
        case "Averses de pluie ou de neige", "Rain showers or flurries":
            return WeatherStatus.RainShowersOrFlurries
        case "Pluie intermittente ou neige", "Periods of rain or snow":
            return WeatherStatus.PeriodsOfRainOrSnow
        case "Neige intermittente", "Periods of snow":
            return WeatherStatus.PeriodsOfSnow
        case "Quelques averses de pluie ou de neige", "A few rain showers or flurries":
            return WeatherStatus.AFewRainShowersOrFlurries
        case "Alternance de soleil et de nuages", "A mix of sun and cloud":
            return WeatherStatus.AMixOfSunAndCloud
        case "Pluie parfois forte", "Rain at times heavy":
            return WeatherStatus.RainAtTimesHeavy
        case "Quelques averses de neige","A few flurries":
            return WeatherStatus.AFewFlurries
        case "Quelques nuages","A few clouds":
            return WeatherStatus.AFewClouds
        case "Dégagement","Clearing":
            return WeatherStatus.Clearing
        case "Brume", "Mist":
            return WeatherStatus.Mist
        case "Faible averse de pluie", "Light Rainshower":
            return WeatherStatus.LightRainshower
        case "Neige", "Snow":
            return WeatherStatus.Snow
        case "Averses", "Showers":
            return WeatherStatus.Showers
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
        let regex = try! NSRegularExpression(pattern: "^.*?:(.*?),", options: [.CaseInsensitive])
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
        let regex = try! NSRegularExpression(pattern: ".*?(Aucune veille ou alerte en vigueur|No watches or warnings in effect|WARNING|AVERTISSEMENT|BULLETIN MÉTÉOROLOGIQUE|WEATHER STATEMENT).*?", options: [])
        let alert = performRegex(regex, text: title, index: 1)
        if alert.isEmpty {
            return false
        }
        
        return true
    }
    
    func extractAlertText(title: String) -> String {
        var regex = try! NSRegularExpression(pattern: "(WARNING|AVERTISSEMENT|BULLETIN MÉTÉOROLOGIQUE|WEATHER STATEMENT)", options: [])
        let alert = performRegex(regex, text: title, index: 1)
        if alert.isEmpty {
            return ""
        }

        regex = try! NSRegularExpression(pattern: "^(.*?)(,|$)", options: [])
        return performRegex(regex, text: title, index: 1)
    }
}
