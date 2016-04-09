//
//  FavoriteCityHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class FavoriteCityHelper {
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
}
