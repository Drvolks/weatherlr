//
//  FavoriteCityHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class PreferenceHelper {
    static func addFavorite(_ city: City) {
        var favorites = getFavoriteCities()
        var newFavorites = [City]()
        
        saveSelectedCity(city)
        newFavorites.append(city)
        
        for i in 0..<favorites.count {
            if city.id != favorites[i].id {
                newFavorites.append(favorites[i])
            }
        }
        
        saveFavoriteCities(newFavorites)
    }
    
    static func getFavoriteCities() -> [City] {
        NSKeyedUnarchiver.setClass(City.self, forClassName: "weatherlr.City")
        if let unarchivedObject = UserDefaults.standard.object(forKey: Constants.favotiteCitiesKey) as? Data {
            if let savedfavorites = NSKeyedUnarchiver.unarchiveObject(with: unarchivedObject) as? [City] {
                return savedfavorites
            }
        }
        
        return [City]()
    }
    
    private static func saveFavoriteCities(_ cities: [City]) {
        let archivedObject = NSKeyedArchiver.archivedData(withRootObject: cities as NSArray)
        let defaults = UserDefaults.standard
        defaults.set(archivedObject, forKey: Constants.favotiteCitiesKey)
        defaults.synchronize()
    }
    
    private static func saveSelectedCity(_ city: City) {
        let archivedObject = NSKeyedArchiver.archivedData(withRootObject: city)
        let defaults = UserDefaults.standard
        defaults.set(archivedObject, forKey: Constants.selectedCityKey)
        defaults.synchronize()
    }
    
    static func getSelectedCity() -> City? {
        NSKeyedUnarchiver.setClass(City.self, forClassName: "weatherlr.City")
        if let unarchivedObject = UserDefaults.standard.object(forKey: Constants.selectedCityKey) as? Data {
            if let selectedCity = NSKeyedUnarchiver.unarchiveObject(with: unarchivedObject) as? City {
                // for legacy City object < 1.1 release
                if selectedCity.radarId.isEmpty {
                    return refreshCity(selectedCity)
                }
                
                return selectedCity
            }
        }
        
        return nil
    }
    
    static func refreshCity(_ city:City) -> City {
        let path = Bundle.main.pathForResource("Cities", ofType: "plist")
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
        
        if let selectedCity = getSelectedCity() {
            if selectedCity.id == city.id {
                saveSelectedCity(newFavorites[0])
            }
        }
    }
    
    static func removeFavorites() {
        let favorites = getFavoriteCities()
        
        if favorites.count == 0 {
            return
        }
        
        var newFavorites = [City]()
        if let city = getSelectedCity() {
            newFavorites.append(city)
        }
        
        saveFavoriteCities(newFavorites)
    }
    
    static func getLanguage() -> Language {
        if let lang = UserDefaults.standard.object(forKey: Constants.languageKey) as? String {
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
        UserDefaults.standard.set(language.rawValue, forKey: Constants.languageKey)
        UserDefaults.standard.synchronize()
        
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
            return locale.substring(to: index.lowerBound)
        }
                
        return locale
    }
}
