//
//  FavoriteCityHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class PreferenceHelper {
    static func addFavorite(city: City) {
        var favorites = getFavoriteCities()
        
        for i in 0..<favorites.count {
            if city.id == favorites[i].id {
                return
            }
        }
        
        favorites.append(city)
        
        saveFavoriteCities(favorites)
        saveSelectedCity(city)
    }
    
    static func getFavoriteCities() -> [City] {
        if let unarchivedObject = NSUserDefaults.standardUserDefaults().objectForKey(Constants.favotiteCitiesKey) as? NSData {
            if let savedfavorites = NSKeyedUnarchiver.unarchiveObjectWithData(unarchivedObject) as? [City] {
                return savedfavorites
            }
        }
        
        return [City]()
    }
    
    static func saveFavoriteCities(cities: [City]) {
        let archivedObject = NSKeyedArchiver.archivedDataWithRootObject(cities as NSArray)
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(archivedObject, forKey: Constants.favotiteCitiesKey)
        defaults.synchronize()
    }
    
    static func saveSelectedCity(city: City) {
        let archivedObject = NSKeyedArchiver.archivedDataWithRootObject(city)
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(archivedObject, forKey: Constants.selectedCityKey)
        defaults.synchronize()
    }
    
    static func getSelectedCity() -> City? {
        if let unarchivedObject = NSUserDefaults.standardUserDefaults().objectForKey(Constants.selectedCityKey) as? NSData {
            if let selectedCity = NSKeyedUnarchiver.unarchiveObjectWithData(unarchivedObject) as? City {
                return selectedCity
            }
        }
        
        return nil
    }
    
    static func removeFavorite(city: City) {
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
    
    static func getLanguage() -> Language {
        if let lang = NSUserDefaults.standardUserDefaults().objectForKey(Constants.languageKey) as? String {
            if let langEnum = Language(rawValue: lang) {
                return langEnum
            }
        } else {
            let preferredLanguage = NSLocale.preferredLanguages()[0]
            if let lang = Language(rawValue: preferredLanguage) {
                saveLanguage(lang)
                return lang
            }
        }
         
         return Language.English
    }
    
    static func saveLanguage(language: Language) {
        NSUserDefaults.standardUserDefaults().setObject(language.rawValue, forKey: Constants.languageKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    static func isFrench() -> Bool {
        if getLanguage() == Language.French {
            return true
        }
        
        return false
    }
}
