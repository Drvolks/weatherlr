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

class PreferenceHelper {
    static func addFavorite(_ city: City) {
        var favorites = getFavoriteCities()
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
    
    static func updateQuickActions() {
        #if os(iOS)
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
    
    static func getFavoriteCities() -> [City] {
        let currentLocation = CityHelper.getCurrentLocationCity()
        
        do {
            var savedfavorites = try getFavoriteCitiesWithClassName("City")
            savedfavorites.insert(currentLocation, at: 0)
            return savedfavorites
        } catch {}
        
        // trying with legacy names
        do {
            var savedfavorites = try getFavoriteCitiesWithClassName("weatherlr.City")
            savedfavorites.insert(currentLocation, at: 0)
            return savedfavorites
        } catch {}
        
        do {
            var savedfavorites = try getFavoriteCitiesWithClassName("weatherlrFree.City")
            savedfavorites.insert(currentLocation, at: 0)
            return savedfavorites
        } catch {}
        
        var savedfavorites = [City]()
        savedfavorites.insert(currentLocation, at: 0)
        return savedfavorites
    }
    
    static func getFavoriteCitiesWithClassName(_ className:String) throws -> [City] {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        NSKeyedUnarchiver.setClass(City.self, forClassName: className)
        
        if let unarchivedObject = defaults.object(forKey: Global.favotiteCitiesKey) as? Data {
            do {
                let savedfavorites = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(unarchivedObject) as! [City]
                return savedfavorites
            } catch {
                // will throw error
            }
        }
        
        throw PreferenceHelperError.unarchiveError
    }
    
    static func switchFavoriteCity(cityId: String) {
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
        NSKeyedArchiver.setClassName("City", for: City.self)
        let archivedObject = NSKeyedArchiver.archivedData(withRootObject: cities as NSArray)
        defaults.set(archivedObject, forKey: Global.favotiteCitiesKey)
        defaults.synchronize()
    }
    
    static func saveSelectedCity(_ city: City) {
        NSKeyedArchiver.setClassName("City", for: City.self)
        let archivedObject = NSKeyedArchiver.archivedData(withRootObject: city)
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        defaults.set(archivedObject, forKey: Global.selectedCityKey)
        defaults.synchronize()
    }
    
    static func getSelectedCity() -> City {
        if let city = getCity(key: Global.selectedCityKey) {
            return city
        }
        
        return CityHelper.getCurrentLocationCity()
    }
    
    private static func getCity(key:String) -> City? {
        do {
            let selectedCity = try getCityWithClassName("City", key:key)
            return selectedCity
        } catch {}
        
        // try with legacy names
        do {
            let selectedCity = try getCityWithClassName("weatherlr.City", key:key)
            return selectedCity
        } catch {}
        
        do {
            let selectedCity = try getCityWithClassName("weatherlrFree.City", key:key)
            return selectedCity
        } catch {}
        
        return CityHelper.getCurrentLocationCity()
    }
    
    private static func getCityWithClassName(_ className:String, key:String) throws -> City? {
        NSKeyedUnarchiver.setClass(City.self, forClassName: className)
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        if let unarchivedObject = defaults.object(forKey: key) as? Data {
            do {
                let selectedCity = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(unarchivedObject) as! City
                
                // for legacy City object < 1.1 release
                if key == Global.selectedCityKey && selectedCity.id != Global.currentLocationCityId && selectedCity.radarId.isEmpty {
                    return refreshCity(selectedCity)
                }
                
                return selectedCity
            } catch {
                // will throw error
            }
        }
        
        throw PreferenceHelperError.unarchiveError
    }
    
    private static func refreshCity(_ city:City) -> City {
        let path = Bundle.main.path(forResource: "Cities", ofType: "plist")
        let cities = (NSKeyedUnarchiver.unarchiveObject(withFile: path!) as? [City])!
        
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
    
    static func removeFavorite(_ city: City) {
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
    
    static func removeFavorites() {
        let favorites = getFavoriteCities()
        
        if favorites.count == 0 {
            return
        }
        
        var newFavorites = [City]()
        newFavorites.append(getSelectedCity())
        
        saveFavoriteCities(newFavorites)
    }
    
    static func getLanguage() -> Language {
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
    
    static func saveLanguage(_ language: Language) {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        defaults.set(language.rawValue, forKey: Global.languageKey)
        defaults.synchronize()
        
        ExpiringCache.instance.removeAllObjects()
    }
    
    static func isFrench() -> Bool {
        if getLanguage() == Language.French {
            return true
        }
        
        return false
    }
    
    static func extractLang(_ locale:String) -> String {
        if let index = locale.range(of: "-") {
            return String(locale[..<index.lowerBound])
        }
                
        return locale
    }
    
    static func upgrade() {
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
                defaults.synchronize()
            }
        }
    }
    
    static func getCityToUse() -> City {
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
    
    static func saveLastLocatedCity(_ city: City) {
        NSKeyedArchiver.setClassName("City", for: City.self)
        let archivedObject = NSKeyedArchiver.archivedData(withRootObject: city)
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        defaults.set(archivedObject, forKey: Global.lastLocatedCityKey)
        defaults.synchronize()
    }
    
    static func removeLastLocatedCity() {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        defaults.removeObject(forKey: Global.lastLocatedCityKey)
        defaults.synchronize()
    }
}
