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
            
            if weatherInformation.weatherDay == WeatherDay.today && weatherInformation.night {
                if result.count > 0 && result[result.count-1].weatherDay == WeatherDay.now {
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
                
                if alert.type != AlertType.none && alert.type != AlertType.ended {
                    result.append(alert)
                }
            }
        }
        
        return result
    }
    
    func convert(_ rssEntry: RssEntry) -> WeatherInformation {
        let night = isNight(rssEntry.title)
        let weatherDay = convertWeatherDay(rssEntry.category, currentDay: day)
        
        let statusText:String
        if weatherDay == .now {
            statusText = extractWeatherConditionNowFromTitle(rssEntry.title)
        } else {
            statusText = extractWeatherCondition(rssEntry.title)
        }

        let temperature:Int
        let weatherStatus:WeatherStatus
        if weatherDay == .now {
            let temperatureText = extractTemperatureNowFromTitle(rssEntry.title)
            temperature = convertTemperature(temperatureText)
            
            if statusText == "" {
                weatherStatus = WeatherStatus.blank
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
        
        if(weatherDay != WeatherDay.now && (!night || weatherDay == WeatherDay.today)) {
            day = day + 1
        }
        
        return result
    }
    
    func convertAlert(_ rssEntry: RssEntry) -> AlertInformation {
        let alertText = extractAlertText(rssEntry.title)
        if !alertText.isEmpty {
            let alertType = extractAlertType(alertText)
            
            return AlertInformation(alertText: alertText, url: rssEntry.link, type:alertType)
        }
        
        return AlertInformation()
    }
    
    func extractAlertType(_ alertText:String) -> AlertType {
        let regex = try! NSRegularExpression(pattern: "(TERMINÉ|ENDED)$", options: [.caseInsensitive])
        let ended = performRegex(regex, text: alertText, index: 1)
        
        if !ended.isEmpty {
            return AlertType.ended
        }
        
        return AlertType.warning
    }
    
    func convertWeatherStatus(_ text: String) -> WeatherStatus {
        switch text.lowercased() {
        case "partiellement nuageux", "partly cloudy":
            return WeatherStatus.partlyCloudy
        case "généralement ensoleillé", "mainly sunny":
            return WeatherStatus.mainlySunny
        case "dégagé", "clear":
            return WeatherStatus.clear
        case "faible neige", "neige faible", "light snow":
            return WeatherStatus.lightSnow
        case "neige ou pluie", "snow or rain", "pluie ou neige", "rain or snow":
            return WeatherStatus.snowOrRain
        case "pluie intermittente", "periods of rain":
            return WeatherStatus.periodsOfRain
        case "possibilité d'averses de pluie ou de neige", "chance of rain showers or flurries", "possibilité d'averses de neige ou de pluie", "chance of flurries or rain showers":
            return WeatherStatus.chanceOfRainShowersOrFlurries
        case "possibilité d'averses de neige", "chance of flurries":
            return WeatherStatus.chanceOfFlurries
        case "passages nuageux", "cloudy periods":
            return WeatherStatus.cloudyPeriods
        case "ensoleillé", "sunny":
            return WeatherStatus.sunny
        case "possibilité d'averses", "chance of showers":
            return WeatherStatus.chanceOfShowers
        case "généralement nuageux", "mostly cloudy", "mainly cloudy":
            return WeatherStatus.mostlyCloudy
        case "nuageux", "cloudy":
            return WeatherStatus.cloudy
        case "pluie faible", "light rain":
            return WeatherStatus.lightRain
        case "pluie", "rain":
            return WeatherStatus.rain
        case "averses de pluie ou de neige", "rain showers or flurries":
            return WeatherStatus.rainShowersOrFlurries
        case "pluie intermittente ou neige", "periods of rain or snow":
            return WeatherStatus.periodsOfRainOrSnow
        case "neige intermittente", "periods of snow":
            return WeatherStatus.periodsOfSnow
        case "quelques averses de pluie ou de neige", "a few rain showers or flurries":
            return WeatherStatus.aFewRainShowersOrFlurries
        case "alternance de soleil et de nuages", "a mix of sun and cloud":
            return WeatherStatus.aMixOfSunAndCloud
        case "pluie parfois forte", "rain at times heavy":
            return WeatherStatus.rainAtTimesHeavy
        case "quelques averses de neige","a few flurries":
            return WeatherStatus.aFewFlurries
        case "quelques nuages","a few clouds":
            return WeatherStatus.aFewClouds
        case "dégagement","clearing":
            return WeatherStatus.clearing
        case "brume", "mist":
            return WeatherStatus.mist
        case "faible averse de pluie", "light rainshower":
            return WeatherStatus.lightRainshower
        case "neige", "snow":
            return WeatherStatus.snow
        case "averses", "showers":
            return WeatherStatus.showers
        case "quelques averses", "a few showers":
            return WeatherStatus.aFewShowers
        case "averses ou bruine", "showers or drizzle":
            return WeatherStatus.showersOrDrizzle
        case "pluie intermittente ou bruine", "periods of rain or drizzle":
            return WeatherStatus.periodsOfRainOrDrizzle
        case "ennuagement", "increasing cloudiness":
            return WeatherStatus.increasingCloudiness
        case "averses de neige", "flurries":
            return WeatherStatus.flurries
        case "possibilité de bruine", "chance of drizzle":
            return WeatherStatus.chanceOfDrizzle
        case "bruine", "drizzle":
            return WeatherStatus.drizzle
        case "neige intermittente ou pluie", "periods of snow or rain", "pluie et neige faibles", "light rain and snow", "faible neige intermittente ou pluie", "periods of light snow or rain", "quelques averses de neige ou de pluie", "a few flurries or rain showers":
            return WeatherStatus.periodsOfSnowOrRain
        case "faible bruine verglaçante", "light freezing drizzle":
            return WeatherStatus.lightFreezingDrizzle
        case "pluie verglaçante intermittente", "periods of freezing rain":
            return WeatherStatus.periodsOfFreezingRain
        case "pluie intermittente ou pluie verglaçante", "periods of rain or freezing rain":
            return WeatherStatus.periodsOfRainOrFreezingRain
        case "bruine intermittente", "periods of drizzle", "bruine faible", "light drizzle":
            return WeatherStatus.periodsOfDrizzle
        case "averses de neige ou de pluie", "flurries or rain showers":
            return WeatherStatus.flurriesOrRainShowers
        case "faible neige intermittente", "periods of light snow":
            return WeatherStatus.periodsOfLightSnow
        case "blizzard":
            return WeatherStatus.blizzard
        case "neige faible et poudrerie élevée", "light snow and blowing snow":
            return WeatherStatus.lightSnowAndBlowingSnow
        case "poudrerie basse", "drifting snow":
            return WeatherStatus.driftingSnow
        case "couvert", "overcast":
            return WeatherStatus.overcast
        case "poudrerie élevée", "poudrerie  élevée", "poudrerie", "blowing snow":
            return WeatherStatus.blowingSnow
        case "généralement dégagé", "mainly clear":
            return WeatherStatus.mainlyClear
        case "neige intermittente ou pluie verglaçante", "faible neige intermittente ou pluie verglaçante", "periods of light snow or freezing rain", "periods of snow or freezing rain":
            return WeatherStatus.periodsOfLightSnowOrFreezingRain
        case "pluie ou pluie verglaçante", "rain or freezing rain":
            return WeatherStatus.rainOrFreezingRain
        case "pluie intermittente mêlée de neige", "periods of rain mixed with snow":
            return WeatherStatus.periodsOfRainMixedWithSnow
        case "neige intermittente et poudrerie", "periods of snow and blowing snow":
            return WeatherStatus.periodsOfSnowAndBlowingSnow
        case "possibilité d'averses ou bruine", "chance of showers or drizzle":
            return WeatherStatus.chanceOfShowersOrDrizzle
        case "bruine mêlée de bruine verglaçante", "drizzle mixed with freezing drizzle":
            return WeatherStatus.drizzleMixedWithFreezingDrizzle
        case "possibilité de bruine mêlée de bruine verglaçante", "chance of drizzle mixed with freezing drizzle":
            return WeatherStatus.chanceOfDrizzleMixedWithFreezingDrizzle
        case "faible averse de neige", "light snowshower":
            return WeatherStatus.lightSnowshower
        case "bruine intermittente mêlée de bruine verglaçante", "periods of drizzle mixed with freezing drizzle":
            return WeatherStatus.periodsOfDrizzleMixedWithFreezingDrizzle
        case "bruine verglaçante ou bruine", "freezing drizzle or drizzle":
            return WeatherStatus.freezingDrizzleOrDrizzle
        case "possibilité d'averses de pluie ou de neige fondante", "chance of rain showers or wet flurries":
            return WeatherStatus.chanceOfRainShowersOrWetFlurries
        case "neige et poudrerie", "snow and blowing snow", "neige et poudrerie élevée", "neige parfois forte et poudrerie", "snow at times heavy and blowing snow":
            return WeatherStatus.snowAndBlowingSnow
        case "neige forte", "heavy snow":
            return WeatherStatus.heavySnow
        case "averses de neige parfois fortes", "flurries at times heavy":
            return WeatherStatus.flurriesAtTimesHeavy
        case "neige mêlée de pluie", "snow mixed with rain":
            return WeatherStatus.snowMixedWithRain
        case "possibilité de neige", "chance of snow":
            return WeatherStatus.chanceOfSnow
        case "possibilité de faible neige", "chance of light snow":
            return WeatherStatus.chanceOfLightSnow
        case "neige parfois forte", "snow at times heavy":
            return WeatherStatus.snowAtTimesHeavy
        case "pluie verglaçante ou neige", "freezing rain or snow":
            return WeatherStatus.freezingRainOrSnow
        case "faible pluie verglaçante", "light freezing rain":
            return WeatherStatus.lightFreezingRain
        case "cristaux de glace", "ice crystals":
            return WeatherStatus.iceCrystals
        case "neige en grains", "snow grains":
            return WeatherStatus.snowGrains
        case "neige fondante", "wet snow":
            return WeatherStatus.wetSnow
        case "averses de neige fondante", "wet flurries":
            return WeatherStatus.wetFlurries
        case "brouillard givrant", "freezing fog":
            return WeatherStatus.freezingFog
        case "brouillard", "fog":
            return WeatherStatus.fog
        case "brume sèche", "haze":
            return WeatherStatus.haze
        case "neige parfois forte mêlée de pluie", "snow at times heavy mixed with rain":
            return WeatherStatus.snowAtTimesHeavyMixedWithRain
        case "neige intermittente mêlée de pluie", "periods of snow mixed with rain":
            return WeatherStatus.periodsOfSnowMixedWithRain
        case "pluie ou bruine", "rain or drizzle":
            return WeatherStatus.rainOrDrizzle
        case "bruine intermittente ou pluie", "periods of drizzle or rain":
            return WeatherStatus.periodsOfDrizzleOrRain
        case "bruine faible et brouillard", "light drizzle and fog":
            return WeatherStatus.lightDrizzleAndFog
        case "pluie faible et brouillard", "light rain and fog":
            return WeatherStatus.lightRainAndFog
        case "bruine intermittente mêlée de pluie", "periods of drizzle mixed with rain":
            return WeatherStatus.periodsOfDrizzleMixedWithRain
        case "neige intermittente mêlée de pluie verglaçante", "periods of snow mixed with freezing rain":
            return WeatherStatus.periodsOfSnowMixedWithFreezingRain
        case "bancs de brouillard", "fog patches":
            return WeatherStatus.fogPatches
        case "pluie mêlée de neige", "rain mixed with snow":
            return WeatherStatus.rainMixedWithSnow
        case "neige mêlée de grésil", "snow mixed with ice pellets":
            return WeatherStatus.snowMixedWithIcePellets
        case "faible neige intermittente mêlée de bruine verglaçante", "periods of light snow mixed with freezing drizzle":
            return WeatherStatus.periodsOfLightSnowMixedWithFreezingDrizzle
        case "fumée", "smoke":
            return WeatherStatus.smoke
        case "neige mêlée de bruine verglaçante", "snow mixed with freezing drizzle":
            return WeatherStatus.snowMixedWithFreezingDrizzle
        case "bruine verglaçante intermittente ou bruine", "periods of freezing drizzle or drizzle":
            return WeatherStatus.periodsOfFreezingDrizzleOrDrizzle
        case "possibilité de bruine ou pluie", "chance of drizzle or rain":
            return WeatherStatus.chanceOfDrizzleOrRain
        case "possibilité d'averses de neige fondante", "chance of wet flurries":
            return WeatherStatus.chanceOfWetFlurries
        case "bruine verglaçante intermittente ou pluie", "periods of freezing drizzle or rain":
            return WeatherStatus.periodsOfFreezingDrizzleOrRain
        case "bruine verglaçante intermittente", "periods of freezing drizzle":
            return WeatherStatus.periodsOfFreezingDrizzle
        case "pluie verglaçante intermittente ou neige", "periods of freezing rain or snow":
            return WeatherStatus.periodsOfFreezingRainOrSnow
        case "pluie verglaçante mêlée de grésil", "freezing rain mixed with ice pellets":
            return WeatherStatus.freezingRainMixedWithIcePellets
        case "pluie verglaçante intermittente mêlée de grésil", "periods of freezing rain mixed with ice pellets":
            return WeatherStatus.periodsOfFreezingRainMixedWithIcePellets
        case "possibilité d'averses ou orages", "chance of showers or thunderstorms", "chance of showers or thundershowers":
            return WeatherStatus.chanceOfShowersOrThunderstorms
        case "possibilité d'averses de neige fondante ou de pluie", "chance of wet flurries or rain showers":
            return WeatherStatus.chanceOfWetFlurriesOrRainShowers
        case "possibilité de pluie", "chance of rain":
            return WeatherStatus.chanceOfRain
        case "faible neige fondante", "light wet snow":
            return WeatherStatus.lightWetSnow
        case "précipitations", "precipitation":
            return WeatherStatus.precipitation
        case "bruine ou pluie", "drizzle or rain":
            return WeatherStatus.drizzleOrRain
        case "pluie verglaçante mêlée de neige", "freezing rain mixed with snow":
            return WeatherStatus.freezingRainMixedWithSnow
        case "bruine verglaçante ou pluie", "freezing drizzle or rain":
            return WeatherStatus.freezingDrizzleOrRain
        case "pluie parfois forte ou bruine", "rain at times heavy or drizzle":
            return WeatherStatus.rainAtTimesHeavyOrDrizzle
        case "faible neige intermittente mêlée de pluie", "periods of light snow mixed with rain":
            return WeatherStatus.periodsOfLightSnowMixedWithRain
        case "quelques averses ou bruine", "a few showers or drizzle":
            return WeatherStatus.aFewShowersOrDrizzle
        case "neige fondante intermittente ou pluie", "periods of wet snow or rain":
            return WeatherStatus.periodsOfWetSnowOrRain
        case "faible neige mêlée de pluie", "light snow mixed with rain":
            return WeatherStatus.lightSnowMixedWithRain
        case "bruine intermittente ou bruine verglaçante", "periods of drizzle or freezing drizzle":
            return WeatherStatus.periodsOfDrizzleOrFreezingDrizzle
        case "neige fondante intermittente", "periods of wet snow":
            return WeatherStatus.periodsOfWetSnow
        case "neige intermittente ou bruine verglaçante", "periods of snow or freezing drizzle":
            return WeatherStatus.periodsOfSnowOrFreezingDrizzle
        case "possibilité de bruine verglaçante", "chance of freezing drizzle":
            return WeatherStatus.chanceOfFreezingDrizzle
        case "bruine verglaçante", "freezing drizzle":
            return WeatherStatus.freezingDrizzle
        case "neige intermittente mêlée de bruine verglaçante", "periods of snow mixed with freezing drizzle":
            return WeatherStatus.periodsOfSnowMixedWithFreezingDrizzle
        case "faible neige ou pluie", "light snow or rain":
            return WeatherStatus.lightSnowOrRain
        case "pluie verglaçante", "freezing rain":
            return WeatherStatus.freezingRain
        case "neige ou pluie verglaçante", "snow or freezing rain":
            return WeatherStatus.snowOrFreezingRain
        case "forte averse de pluie", "heavy rainshower":
            return WeatherStatus.heavyRainshower
        case "quelques averses ou orages", "a few showers or thunderstorms", "a few showers or thundershowers":
            return WeatherStatus.aFewShowersOrThunderstorms
        case "orage", "thunderstorm":
            return WeatherStatus.thunderstorm
        case "orage avec averse de pluie", "thunderstorm with light rainshowers":
            return WeatherStatus.thunderstormWithLightRainshowers
        case "neige ou grésil", "snow or ice pellets":
            return WeatherStatus.snowOrIcePellets
        case "grésil ou neige", "ice pellets or snow":
            return WeatherStatus.icePelletsOrSnow
        case "averses de neige fondante ou de pluie", "wet flurries or rain showers":
            return WeatherStatus.wetFlurriesOrRainShowers
        case "faible neige ou pluie verglaçante", "light snow or freezing rain":
            return WeatherStatus.lightSnowOrFreezingRain
        case "pluie parfois forte ou neige", "rain at times heavy or snow":
            return WeatherStatus.rainAtTimesHeavyOrSnow
        case "neige parfois forte ou pluie", "snow at times heavy or rain":
            return WeatherStatus.snowAtTimesHeavyOrRain
        case "brouillard se dissipant", "fog dissipating":
            return WeatherStatus.fogDissipating
        case "averses ou orages", "showers or thunderstorms", "showers or thundershowers":
            return WeatherStatus.showersOrThunderstorms
        case "orage avec faible pluie", "thunderstorm with light rain":
            return WeatherStatus.thunderstormWithLightRain
        case "possibilité de pluie ou bruine", "chance of rain or drizzle":
            return WeatherStatus.chanceOfRainOrDrizzle
        case "possibilité de neige mêlée de pluie", "chance of snow mixed with rain":
            return WeatherStatus.chanceOfSnowMixedWithRain
        case "possibilité de neige ou pluie", "chance of snow or rain":
            return WeatherStatus.chanceOfSnowOrRain
        case "possibilité d'averses parfois fortes", "chance of showers at times heavy":
            return WeatherStatus.chanceOfShowersAtTimesHeavy
        case "averses parfois fortes", "showers at times heavy":
            return WeatherStatus.showersAtTimesHeavy
        case "possibilité d'orages", "chance of thunderstorms":
            return WeatherStatus.chanceOfThunderstorms
        case "averses parfois fortes ou orages", "showers at times heavy or thundershowers":
            return WeatherStatus.showersAtTimesHeavyOrThundershowers
        case "averses de pluie ou de neige fondante", "rain showers or wet flurries":
            return WeatherStatus.rainShowersOrWetFlurries
        case "neige parfois forte mêlée de grésil", "snow at times heavy mixed with ice pellets":
            return WeatherStatus.snowAtTimesHeavyMixedWithIcePellets
        case "grésil mêlé de neige", "ice pellets mixed with snow":
            return WeatherStatus.icePelletsMixedWithSnow
        case "pluie verglaçante ou pluie", "freezing rain or rain":
            return WeatherStatus.freezingRainOrRain
        case "possibilité de pluie verglaçante", "chance of freezing rain":
            return WeatherStatus.chanceOfFreezingRain
        case "neige intermittente mêlée de grésil", "periods of snow mixed with ice pellets":
            return WeatherStatus.periodsOfSnowMixedWithIcePellets
        case "pluie parfois forte ou pluie verglaçante", "rain at times heavy or freezing rain":
            return WeatherStatus.rainAtTimesHeavyOrFreezingRain
        case "grésil mêlé de pluie verglaçante", "ice pellets mixed with freezing rain":
            return WeatherStatus.icePelletsMixedWithFreezingRain
        case "pluie verglaçante ou grésil", "freezing rain or ice pellets":
            return WeatherStatus.freezingRainOrIcePellets
        case "grésil", "ice pellets":
            return WeatherStatus.icePellets
        case "pluie mêlée de pluie verglaçante", "rain mixed with freezing rain":
            return WeatherStatus.rainMixedWithFreezingRain
        case "pluie et bruine faibles", "light rain and drizzle":
            return WeatherStatus.lightRainAndDrizzle
        default:
            return convertWeatherStatusWithRegex(text)
        }
    }
    
    func convertWeatherStatusWithRegex(_ text: String) -> WeatherStatus {
        var regex = try! NSRegularExpression(pattern: "Nuageux avec \\d* pour cent de probabilité d'averses de neige", options: [.caseInsensitive])
        var match = regex.matches(in: text, options: [], range: NSMakeRange(0, text.distance(from: text.startIndex, to: text.endIndex)))
        if match.count > 0 {
            return WeatherStatus.cloudyWithXPercentChanceOfFlurries
        }
        
        regex = try! NSRegularExpression(pattern: "Cloudy with \\d* percent chance of flurries", options: [.caseInsensitive])
        match = regex.matches(in: text, options: [], range: NSMakeRange(0, text.distance(from: text.startIndex, to: text.endIndex)))
        if match.count > 0 {
            return WeatherStatus.cloudyWithXPercentChanceOfFlurries
        }
        
        return WeatherStatus.na
    }
    
    func convertWeatherDay(_ text: String, currentDay: Int) -> WeatherDay {
        switch text {
        case "Conditions actuelles", "Current Conditions":
            return WeatherDay.now
        case "Prévisions météo", "Weather Forecasts":
            if let day = WeatherDay(rawValue: currentDay) {
                return day
            }
            return WeatherDay.na
        default:
            return WeatherDay.na
        }
    }
    
    func performRegex(_ regex: NSRegularExpression, text: String, index: Int) -> String {
        let results = regex.matches(in: text, options: [], range: NSMakeRange(0, text.distance(from: text.startIndex, to: text.endIndex)))
        if let result = results.first {
            var condition = (text as NSString).substring(with: result.range(at: index))
            condition = condition.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return condition
        }
        
        return ""
    }
    
    
    func extractWeatherConditionNowFromSummary(_ summary: String) -> String {
        let regex = try! NSRegularExpression(pattern: "<b>Condition:</b>(.*?)<br/>", options: [.caseInsensitive])
        return performRegex(regex, text: summary, index: 1)
    }
    
    func extractTemperatureNowFromSummary(_ summary: String) -> String {
        let regex = try! NSRegularExpression(pattern: "<b>(Temperature|Température):</b>(.*?)&deg;", options: [.caseInsensitive])
        return performRegex(regex, text: summary, index: 2)
    }
    
    func extractWeatherConditionNowFromTitle(_ title: String) -> String {
        let regex = try! NSRegularExpression(pattern: "^.*?:([^0-9]*?),", options: [.caseInsensitive])
        return performRegex(regex, text: title, index: 1)
    }
    
    func extractTemperatureNowFromTitle(_ title: String) -> String {
        let regex = try! NSRegularExpression(pattern: ".*?[,:]? ([-\\d,\\.]*?)(°|&#xB0;)", options: [.caseInsensitive])
        return performRegex(regex, text: title, index: 1)
    }
    
    func extractWeatherCondition(_ summary: String) -> String {
        let regex = try! NSRegularExpression(pattern: "^.*?:(.*?)\\.", options: [.caseInsensitive])
        return performRegex(regex, text: summary, index: 1)
    }
    
    func extractTemperature(_ summary: String) -> String {
        let regex = try! NSRegularExpression(pattern: ".*?(High|Low|Maximum|Minimum|stables près de|steady near|à la baisse pour atteindre|falling to|à la hausse pour atteindre|rising to) (.*?)(\\.|with|avec|sauf|except|en après-midi|in the afternoon|au cours de la nuit|by morning|cet après-midi|this afternoon|ce matin puis à la hausse|this morning then rising|en soirée puis à la baisse|in the evening then falling|ce matin puis stables|this morning then steady)", options: [.caseInsensitive])
        return performRegex(regex, text: summary, index: 2)
    }
    
    func convertTemperature(_ temperature: String) -> Int {
        let data = temperature.replacingOccurrences(of: ",", with: ".")
        
        if data == "zéro" || data == "zero" {
            return 0
        }
        
        if let result = Double(data) {
            return Int(round(result))
        }
        
        return 0
    }
    
    func convertTemperatureWithTextSign(_ temperature: String) -> Int {
        let text = temperature.lowercased()
        
        var regex = try! NSRegularExpression(pattern: "^(plus|minus|moins)", options: [.caseInsensitive])
        let sign = performRegex(regex, text: text, index: 1)
        regex = try! NSRegularExpression(pattern: ".*?([\\d\\.,]*)$", options: [.caseInsensitive])
        let temp = performRegex(regex, text: text, index: 1)
        
        var tempDouble = convertTemperature(temp)
        
        if sign == "minus" || sign == "moins" {
            tempDouble = tempDouble * -1
        }
        
        return tempDouble
    }
    
    func nettoyerDetail(_ text: String) -> String {
        let regex = try! NSRegularExpression(pattern: "(Prévisions émises|Forecast issued).*$", options: [.caseInsensitive])
        let textRegex = NSMutableString(string: text)
        regex.replaceMatches(in: textRegex, options: .withTransparentBounds, range: NSMakeRange(0, text.distance(from: text.startIndex, to: text.endIndex)), withTemplate: "")
        let result = textRegex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        return result
    }
    
    func isMaximumTemperature(_ summary: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "(High|Maximum)", options: [.caseInsensitive])
        let highLow = performRegex(regex, text: summary, index: 1)
        if !highLow.isEmpty {
            return true
        }
        
        return false
    }
    
    func isNight(_ title: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "(Ce soir|Soir et nuit|Night)", options: [.caseInsensitive])
        let night = performRegex(regex, text: title, index: 1)
        if night.isEmpty {
            return false
        }
        
        return true
    }
    
    func extractWhen(_ title: String) -> String {
        let regex = try! NSRegularExpression(pattern: "^(.*?):", options: [.caseInsensitive])
        return performRegex(regex, text: title, index: 1)
    }
    
    func extractTendency(_ title: String) -> Tendency {
        let regex = try! NSRegularExpression(pattern: ".*?(High|Low|Maximum|Minimum|stables|steady)", options: [.caseInsensitive])
        let tendency = performRegex(regex, text: title, index: 1)
        
        switch tendency {
        case "Maximum", "High":
            return Tendency.maximum
        case "Minimum", "Low":
            return Tendency.minimum
        case "stables", "steady":
            return Tendency.steady
        default:
            return Tendency.na
        }
    }
    
    func isAlert(_ title: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: ".*?(Aucune veille ou alerte en vigueur|No watches or warnings in effect|IN EFFECT|" + alerts + ").*?", options: [])
        let alert = performRegex(regex, text: title, index: 1)
        if alert.isEmpty {
            return false
        }
        
        return true
    }
    
    func extractAlertText(_ title: String) -> String {
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
