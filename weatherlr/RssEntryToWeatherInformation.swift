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
    var day:Int = 0
    let alerts = "AVERTISSEMENT|ALERTE|WARNING|VEILLE|WATCH|AVIS|ADVISORY|BULLETIN|STATEMENT"
    
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
        for i in 0..<rssEntries.count {
            if(isAlert(rssEntries[i].title)) {
                debut = i+1
            } else {
                break
            }
        }
        
        for i in debut..<rssEntries.count {
            let weatherInformation = convert(rssEntries[i])
            
            if weatherInformation.weatherDay == WeatherDay.Today && weatherInformation.night {
                if result.count > 0 && result[result.count-1].weatherDay == WeatherDay.Now {
                    result[result.count-1].night = true
                }
            }
            
            result.append(weatherInformation)
        }
        
        return result
    }
    
    func getAlerts() -> [AlertInformation] {
        var result = [AlertInformation]()
        
        for i in 0..<rssEntries.count {
            if(isAlert(rssEntries[i].title)) {
                let alert = convertAlert(rssEntries[i])
                
                if alert.type != AlertType.None && alert.type != AlertType.Ended {
                    result.append(alert)
                }
            }
        }
        
        return result
    }
    
    func convert(rssEntry: RssEntry) -> WeatherInformation {
        let night = isNight(rssEntry.title)
        let weatherDay = convertWeatherDay(rssEntry.category, currentDay: day)
        
        let statusText:String;
        if weatherDay == .Now {
            statusText = extractWeatherConditionNowFromTitle(rssEntry.title)
        } else {
            statusText = extractWeatherCondition(rssEntry.title)
        }

        let temperature:Int
        let weatherStatus:WeatherStatus
        if weatherDay == .Now {
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

        let result = WeatherInformation(temperature: temperature, weatherStatus: weatherStatus, weatherDay: weatherDay, summary: rssEntry.title, detail: detail, tendancy: tendendy, when: when, night: night)
        
        if(weatherDay != WeatherDay.Now && (!night || weatherDay == WeatherDay.Today)) {
            day = day + 1
        }
        
        return result
    }
    
    func convertAlert(rssEntry: RssEntry) -> AlertInformation {
        let alertText = extractAlertText(rssEntry.title)
        if !alertText.isEmpty {
            let alertType = extractAlertType(alertText)
            
            return AlertInformation(alertText: alertText, url: rssEntry.link, type:alertType)
        }
        
        return AlertInformation()
    }
    
    func extractAlertType(alertText:String) -> AlertType {
        let regex = try! NSRegularExpression(pattern: "(TERMINÉ|ENDED)$", options: [.CaseInsensitive])
        let ended = performRegex(regex, text: alertText, index: 1)
        
        if !ended.isEmpty {
            return AlertType.Ended
        }
        
        return AlertType.Warning
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
        case "neige intermittente ou pluie", "periods of snow or rain", "pluie et neige faibles", "light rain and snow", "faible neige intermittente ou pluie", "periods of light snow or rain", "quelques averses de neige ou de pluie", "a few flurries or rain showers":
            return WeatherStatus.PeriodsOfSnowOrRain
        case "faible bruine verglaçante", "light freezing drizzle":
            return WeatherStatus.LightFreezingDrizzle
        case "pluie verglaçante intermittente", "periods of freezing rain":
            return WeatherStatus.PeriodsOfFreezingRain
        case "pluie intermittente ou pluie verglaçante", "periods of rain or freezing rain":
            return WeatherStatus.PeriodsOfRainOrFreezingRain
        case "bruine intermittente", "periods of drizzle", "bruine faible", "light drizzle":
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
        case "possibilité d'averses de pluie ou de neige fondante", "chance of rain showers or wet flurries":
            return WeatherStatus.ChanceOfRainShowersOrWetFlurries
        case "neige et poudrerie", "snow and blowing snow", "neige et poudrerie élevée", "neige parfois forte et poudrerie", "snow at times heavy and blowing snow":
            return WeatherStatus.SnowAndBlowingSnow
        case "neige forte", "heavy snow":
            return WeatherStatus.HeavySnow
        case "averses de neige parfois fortes", "flurries at times heavy":
            return WeatherStatus.FlurriesAtTimesHeavy
        case "neige mêlée de pluie", "snow mixed with rain":
            return WeatherStatus.SnowMixedWithRain
        case "possibilité de neige", "chance of snow":
            return WeatherStatus.ChanceOfSnow
        case "possibilité de faible neige", "chance of light snow":
            return WeatherStatus.ChanceOfLightSnow
        case "neige parfois forte", "snow at times heavy":
            return WeatherStatus.SnowAtTimesHeavy
        case "pluie verglaçante ou neige", "freezing rain or snow":
            return WeatherStatus.FreezingRainOrSnow
        case "faible pluie verglaçante", "light freezing rain":
            return WeatherStatus.LightFreezingRain
        case "cristaux de glace", "ice crystals":
            return WeatherStatus.IceCrystals
        case "neige en grains", "snow grains":
            return WeatherStatus.SnowGrains
        case "neige fondante", "wet snow":
            return WeatherStatus.WetSnow
        case "averses de neige fondante", "wet flurries":
            return WeatherStatus.WetFlurries
        case "brouillard givrant", "freezing fog":
            return WeatherStatus.FreezingFog
        case "brouillard", "fog":
            return WeatherStatus.Fog
        case "brume sèche", "haze":
            return WeatherStatus.Haze
        case "neige parfois forte mêlée de pluie", "snow at times heavy mixed with rain":
            return WeatherStatus.SnowAtTimesHeavyMixedWithRain
        case "neige intermittente mêlée de pluie", "periods of snow mixed with rain":
            return WeatherStatus.PeriodsOfSnowMixedWithRain
        case "pluie ou bruine", "rain or drizzle":
            return WeatherStatus.RainOrDrizzle
        case "bruine intermittente ou pluie", "periods of drizzle or rain":
            return WeatherStatus.PeriodsOfDrizzleOrRain
        case "bruine faible et brouillard", "light drizzle and fog":
            return WeatherStatus.LightDrizzleAndFog
        case "pluie faible et brouillard", "light rain and fog":
            return WeatherStatus.LightRainAndFog
        case "bruine intermittente mêlée de pluie", "periods of drizzle mixed with rain":
            return WeatherStatus.PeriodsOfDrizzleMixedWithRain
        case "neige intermittente mêlée de pluie verglaçante", "periods of snow mixed with freezing rain":
            return WeatherStatus.PeriodsOfSnowMixedWithFreezingRain
        case "bancs de brouillard", "fog patches":
            return WeatherStatus.FogPatches
        case "pluie mêlée de neige", "rain mixed with snow":
            return WeatherStatus.RainMixedWithSnow
        case "neige mêlée de grésil", "snow mixed with ice pellets":
            return WeatherStatus.SnowMixedWithIcePellets
        case "faible neige intermittente mêlée de bruine verglaçante", "periods of light snow mixed with freezing drizzle":
            return WeatherStatus.PeriodsOfLightSnowMixedWithFreezingDrizzle
        case "fumée", "smoke":
            return WeatherStatus.Smoke
        case "neige mêlée de bruine verglaçante", "snow mixed with freezing drizzle":
            return WeatherStatus.SnowMixedWithFreezingDrizzle
        case "bruine verglaçante intermittente ou bruine", "periods of freezing drizzle or drizzle":
            return WeatherStatus.PeriodsOfFreezingDrizzleOrDrizzle
        case "possibilité de bruine ou pluie", "chance of drizzle or rain":
            return WeatherStatus.ChanceOfDrizzleOrRain
        case "possibilité d'averses de neige fondante", "chance of wet flurries":
            return WeatherStatus.ChanceOfWetFlurries
        case "bruine verglaçante intermittente ou pluie", "periods of freezing drizzle or rain":
            return WeatherStatus.PeriodsOfFreezingDrizzleOrRain
        case "bruine verglaçante intermittente", "periods of freezing drizzle":
            return WeatherStatus.PeriodsOfFreezingDrizzle
        case "pluie verglaçante intermittente ou neige", "periods of freezing rain or snow":
            return WeatherStatus.PeriodsOfFreezingRainOrSnow
        case "pluie verglaçante mêlée de grésil", "freezing rain mixed with ice pellets":
            return WeatherStatus.FreezingRainMixedWithIcePellets
        case "pluie verglaçante intermittente mêlée de grésil", "periods of freezing rain mixed with ice pellets":
            return WeatherStatus.PeriodsOfFreezingRainMixedWithIcePellets
        case "possibilité d'averses ou orages", "chance of showers or thunderstorms", "chance of showers or thundershowers":
            return WeatherStatus.ChanceOfShowersOrThunderstorms
        case "possibilité d'averses de neige fondante ou de pluie", "chance of wet flurries or rain showers":
            return WeatherStatus.ChanceOfWetFlurriesOrRainShowers
        case "possibilité de pluie", "chance of rain":
            return WeatherStatus.ChanceOfRain
        case "faible neige fondante", "light wet snow":
            return WeatherStatus.LightWetSnow
        case "précipitations", "precipitation":
            return WeatherStatus.Precipitation
        case "bruine ou pluie", "drizzle or rain":
            return WeatherStatus.DrizzleOrRain
        case "pluie verglaçante mêlée de neige", "freezing rain mixed with snow":
            return WeatherStatus.FreezingRainMixedWithSnow
        case "bruine verglaçante ou pluie", "freezing drizzle or rain":
            return WeatherStatus.FreezingDrizzleOrRain
        case "pluie parfois forte ou bruine", "rain at times heavy or drizzle":
            return WeatherStatus.RainAtTimesHeavyOrDrizzle
        case "faible neige intermittente mêlée de pluie", "periods of light snow mixed with rain":
            return WeatherStatus.PeriodsOfLightSnowMixedWithRain
        case "quelques averses ou bruine", "a few showers or drizzle":
            return WeatherStatus.AFewShowersOrDrizzle
        case "neige fondante intermittente ou pluie", "periods of wet snow or rain":
            return WeatherStatus.PeriodsOfWetSnowOrRain
        case "faible neige mêlée de pluie", "light snow mixed with rain":
            return WeatherStatus.LightSnowMixedWithRain
        case "bruine intermittente ou bruine verglaçante", "periods of drizzle or freezing drizzle":
            return WeatherStatus.PeriodsOfDrizzleOrFreezingDrizzle
        case "neige fondante intermittente", "periods of wet snow":
            return WeatherStatus.PeriodsOfWetSnow
        case "neige intermittente ou bruine verglaçante", "periods of snow or freezing drizzle":
            return WeatherStatus.PeriodsOfSnowOrFreezingDrizzle
        case "possibilité de bruine verglaçante", "chance of freezing drizzle":
            return WeatherStatus.ChanceOfFreezingDrizzle
        case "bruine verglaçante", "freezing drizzle":
            return WeatherStatus.FreezingDrizzle
        case "neige intermittente mêlée de bruine verglaçante", "periods of snow mixed with freezing drizzle":
            return WeatherStatus.PeriodsOfSnowMixedWithFreezingDrizzle
        case "faible neige ou pluie", "light snow or rain":
            return WeatherStatus.LightSnowOrRain
        case "pluie verglaçante", "freezing rain":
            return WeatherStatus.FreezingRain
        case "neige ou pluie verglaçante", "snow or freezing rain":
            return WeatherStatus.SnowOrFreezingRain
        case "forte averse de pluie", "heavy rainshower":
            return WeatherStatus.HeavyRainshower
        case "quelques averses ou orages", "a few showers or thunderstorms":
            return WeatherStatus.AFewShowersOrThunderstorms
        case "orage", "thunderstorm":
            return WeatherStatus.Thunderstorm
        case "orage avec averse de pluie", "thunderstorm with light rainshowers":
            return WeatherStatus.ThunderstormWithLightRainshowers
        case "neige ou grésil", "snow or ice pellets":
            return WeatherStatus.SnowOrIcePellets
        case "grésil ou neige", "ice pellets or snow":
            return WeatherStatus.IcePelletsOrSnow
        case "averses de neige fondante ou de pluie", "wet flurries or rain showers":
            return WeatherStatus.WetFlurriesOrRainShowers
        case "faible neige ou pluie verglaçante", "light snow or freezing rain":
            return WeatherStatus.LightSnowOrFreezingRain
        case "pluie parfois forte ou neige", "rain at times heavy or snow":
            return WeatherStatus.RainAtTimesHeavyOrSnow
        case "neige parfois forte ou pluie", "snow at times heavy or rain":
            return WeatherStatus.SnowAtTimesHeavyOrRain
        case "brouillard se dissipant", "fog dissipating":
            return WeatherStatus.FogDissipating
        case "averses ou orages", "showers or thunderstorms":
            return WeatherStatus.ShowersOrThunderstorms
        case "orage avec faible pluie", "thunderstorm with light rain":
            return WeatherStatus.ThunderstormWithLightRain
        case "possibilité de pluie ou bruine", "chance of rain or drizzle":
            return WeatherStatus.ChanceOfRainOrDrizzle
        case "possibilité de neige mêlée de pluie", "chance of snow mixed with rain":
            return WeatherStatus.ChanceOfSnowMixedWithRain
        case "possibilité de neige ou pluie", "chance of snow or rain":
            return WeatherStatus.ChanceOfSnowOrRain
        case "possibilité d'averses parfois fortes", "chance of showers at times heavy":
            return WeatherStatus.ChanceOfShowersAtTimesHeavy
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
    
    func convertWeatherDay(text: String, currentDay: Int) -> WeatherDay {
        switch text {
        case "Conditions actuelles", "Current Conditions":
            return WeatherDay.Now
        case "Prévisions météo", "Weather Forecasts":
            if let day = WeatherDay(rawValue: currentDay) {
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
        let regex = try! NSRegularExpression(pattern: ".*?(High|Low|Maximum|Minimum|stables près de|steady near|à la baisse pour atteindre|falling to|à la hausse pour atteindre|rising to) (.*?)(\\.|with|avec|sauf|except|en après-midi|in the afternoon|au cours de la nuit|by morning|cet après-midi|this afternoon|ce matin puis à la hausse|this morning then rising)", options: [.CaseInsensitive])
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
        let regex = try! NSRegularExpression(pattern: ".*?(Aucune veille ou alerte en vigueur|No watches or warnings in effect|IN EFFECT|" + alerts + ").*?", options: [])
        let alert = performRegex(regex, text: title, index: 1)
        if alert.isEmpty {
            return false
        }
        
        return true
    }
    
    func extractAlertText(title: String) -> String {
        var regex = try! NSRegularExpression(pattern: "(" + alerts + ")", options: [])
        let alert = performRegex(regex, text: title, index: 1)
        if alert.isEmpty {
            return ""
        }

        regex = try! NSRegularExpression(pattern: "^(.*?)(,|$)", options: [])
        let alertText = performRegex(regex, text: title, index: 1)
        
        return alertText
    }
}
