//
//  FavoriteCityHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
#if os(iOS)
    import UIKit
#endif

public class PreferenceHelper {
    public static func addFavorite(_ city: City) {
        let favorites = getFavoriteCities()
        var newFavorites = [City]()
        
        saveSelectedCity(city)
        if city.id != Global.currentLocationCityId {
            newFavorites.append(city)
        }
        
        for i in 0..<favorites.count {
            if city.id != favorites[i].id && favorites[i].id != Global.currentLocationCityId {
                newFavorites.append(favorites[i])
            }
        }
        
        saveFavoriteCities(newFavorites)
        updateQuickActions()
    }
    
    public static func updateQuickActions() {
        #if os(iOS) && !WIDGET_EXTENSION
            var shortcutItems = [UIApplicationShortcutItem]()
            let cities = PreferenceHelper.getFavoriteCities()

            var i = 0
            for city in cities {
                let shortcutItem = UIApplicationShortcutItem(type: "City:" + city.id, localizedTitle: CityHelper.cityName(city))
                shortcutItems.append(shortcutItem)

                i = i+1
                if(i>3) {
                    break
                }
            }

            UIApplication.shared.shortcutItems = shortcutItems
        #endif
    }
    
    public static func getFavoriteCities() -> [City] {
        let currentLocation = CityHelper.getCurrentLocationCity()
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!

        if let data = defaults.object(forKey: Global.favotiteCitiesKey) as? Data {
            // Try modern JSON decoding first
            if let cities = try? JSONDecoder().decode([City].self, from: data) {
                var result = cities
                result.insert(currentLocation, at: 0)
                return result
            }

            // Fall back to legacy NSKeyedArchiver format and auto-migrate
            LegacyCity.registerClassMappings()
            if let legacyCities = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [LegacyCity] {
                let cities = legacyCities.map { $0.toCity() }
                saveFavoriteCities(cities)
                var result = cities
                result.insert(currentLocation, at: 0)
                return result
            }
        }

        var result = [City]()
        result.insert(currentLocation, at: 0)
        return result
    }
    
    public static func switchFavoriteCity(cityId: String) {
        let cities = getFavoriteCities()
        
        for city in cities {
            if city.id == cityId {
                addFavorite(city)
                break;
            }
        }
    }
    
    fileprivate static func saveFavoriteCities(_ cities: [City]) {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        let data = try! JSONEncoder().encode(cities)
        defaults.set(data, forKey: Global.favotiteCitiesKey)
    }
    
    public static func saveSelectedCity(_ city: City) {
        let data = try! JSONEncoder().encode(city)
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        defaults.set(data, forKey: Global.selectedCityKey)
    }
    
    public static func getSelectedCity() -> City {
        if let city = getCity(key: Global.selectedCityKey) {
            return city
        }
        
        return CityHelper.getCurrentLocationCity()
    }
    
    private static func getCity(key:String) -> City? {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        guard let data = defaults.object(forKey: key) as? Data else {
            return nil
        }

        // Try modern JSON decoding first
        if let city = try? JSONDecoder().decode(City.self, from: data) {
            if key == Global.selectedCityKey && city.id != Global.currentLocationCityId && city.radarId.isEmpty {
                return refreshCity(city)
            }
            return city
        }

        // Fall back to legacy NSKeyedArchiver format and auto-migrate
        LegacyCity.registerClassMappings()
        if let legacyCity = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? LegacyCity {
            let city = legacyCity.toCity()
            // Re-save in modern format
            let encoded = try! JSONEncoder().encode(city)
            defaults.set(encoded, forKey: key)

            if key == Global.selectedCityKey && city.id != Global.currentLocationCityId && city.radarId.isEmpty {
                return refreshCity(city)
            }
            return city
        }

        return nil
    }
    
    private static func refreshCity(_ city:City) -> City {
        let cities = CityHelper.loadAllCities()
        
        for i in 0..<cities.count {
            let currentCity = cities[i]
            if currentCity.id == city.id {
                // avoid infinite loop
                saveSelectedCity(currentCity)
                
                removeFavorite(currentCity)
                
                var favorites = getFavoriteCities()
                favorites.append(currentCity)
                saveFavoriteCities(favorites)
                
                // reset selected to current
                saveSelectedCity(currentCity)
                return currentCity
            }
        }
        
        return city
    }
    
    public static func removeFavorite(_ city: City) {
        let favorites = getFavoriteCities()
        
        if favorites.count == 0 {
            return
        }
        
        var newFavorites = [City]()
        
        for i in 0..<favorites.count {
            if city.id != favorites[i].id {
                newFavorites.append(favorites[i])
            }
        }
        
        saveFavoriteCities(newFavorites)
        
        let selectedCity = getSelectedCity()
            if selectedCity.id == city.id {
                saveSelectedCity(newFavorites[0])
            }
    }
    
    public static func removeFavorites() {
        let favorites = getFavoriteCities()
        
        if favorites.count == 0 {
            return
        }
        
        var newFavorites = [City]()
        newFavorites.append(getSelectedCity())
        
        saveFavoriteCities(newFavorites)
    }
    
    public static func getLanguage() -> Language {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        if let lang = defaults.object(forKey: Global.languageKey) as? String {
            if let langEnum = Language(rawValue: lang) {
                return langEnum
            }
        } else {
            let preferredLanguage = extractLang(Locale.preferredLanguages[0])
            if let lang = Language(rawValue: preferredLanguage) {
                saveLanguage(lang)
                return lang
            }
        }
         
         return Language.English
    }
    
    public static func saveLanguage(_ language: Language) {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        defaults.set(language.rawValue, forKey: Global.languageKey)

        
        WeatherHelper.cache.removeAllObjects()
    }
    
    public static func isFrench() -> Bool {
        if getLanguage() == Language.French {
            return true
        }
        
        return false
    }
    
    public static func extractLang(_ locale:String) -> String {
        if let index = locale.range(of: "-") {
            return String(locale[..<index.lowerBound])
        }
                
        return locale
    }
    
    public static func upgrade() {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        var shouldUpdateQuickActions = false
        var previousVersion = Double(0)
        
        if let version = defaults.object(forKey: Global.versionKey) as? Double {
            previousVersion = version
            
            if version < 2.5 {
                shouldUpdateQuickActions = true
            }
        } else {
            shouldUpdateQuickActions = true
        }
        
        if shouldUpdateQuickActions {
            updateQuickActions()
        }
        
        if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let currentVersionDouble = Double(currentVersion)
            
            if previousVersion != currentVersionDouble {
                defaults.set(currentVersionDouble, forKey: Global.versionKey)
        
            }
        }
    }
    
    public static func getCityToUse() -> City {
        let selectedCity = getSelectedCity()
            if selectedCity.id == Global.currentLocationCityId {
                if let city = getCity(key: Global.lastLocatedCityKey) {
                    return city
                }
            } else {
                return selectedCity
            }
        
        return CityHelper.getCurrentLocationCity()
    }
    
    public static func saveLastLocatedCity(_ city: City) {
        let data = try! JSONEncoder().encode(city)
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        defaults.set(data, forKey: Global.lastLocatedCityKey)
    }
    
    public static func removeLastLocatedCity() {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        defaults.removeObject(forKey: Global.lastLocatedCityKey)

    }

    #if ENABLE_PWS
    // MARK: - PWS

    public static func getPWSStations() -> [PWSStation] {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        guard let data = defaults.data(forKey: Global.pwsStationsKey) else { return [] }
        return (try? JSONDecoder().decode([PWSStation].self, from: data)) ?? []
    }

    public static func savePWSStations(_ stations: [PWSStation]) {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        let data = try! JSONEncoder().encode(stations)
        defaults.set(data, forKey: Global.pwsStationsKey)
    }

    private nonisolated(unsafe) static let secretsPlist: [String: String]? = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
            return nil
        }
        return dict
    }()

    public static func getPWSApiKey() -> String? {
        return secretsPlist?["PWS_API_KEY"]
    }

    public static func hasPWSCredentials() -> Bool {
        guard let apiKey = getPWSApiKey(), !apiKey.isEmpty else {
            return false
        }
        return true
    }
    #endif
}
