//
//  CityHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-09.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class CityHelper {
    static func searchCity(_ searchText: String, allCityList: [City]) -> [City] {
        var newFilteredList = [City]()
        
        for i in 0..<allCityList.count {
            let city = allCityList[i]
            
            let name = cityNameForSearch(city)
            
            let searched = searchText.uppercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "en"))
            
            if name.contains(searched) {
                newFilteredList.append(city)
            }
        }
        
        return newFilteredList
    }
    
    static func searchCityStartingWith(_ searchText: String, allCityList: [City]) -> [City] {
        var newFilteredList = [City]()
        
        for i in 0..<allCityList.count {
            let city = allCityList[i]
            
            let name = cityNameForSearch(city)
            
            if name.uppercased().hasPrefix(searchText) {
                newFilteredList.append(city)
            }
        }
        
        return newFilteredList
    }
    
    static func searchSingleCity(_ searchText: String, allCityList: [City]) -> City? {
        let result = searchCity(searchText, allCityList: allCityList)
        if result.count > 0 {
            return result[0]
        }
        
        return nil
    }
    
    
    static func cityNameForSearch(_ city: City) -> String {
        var name = city.englishName
        if(PreferenceHelper.isFrench()) {
            name = city.frenchName
        }
        
        name = name.uppercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "en"))
        
        return name
    }
    
    static func cityName(_ city:City) -> String {
        var name = city.englishName
        if(PreferenceHelper.isFrench()) {
            name = city.frenchName
        }
        
        return name;
    }
    
    static func sortCityList(_ cityListToSort: [City]) -> [City] {
        var newCityList = cityListToSort
        
        if PreferenceHelper.isFrench() {
            newCityList.sort(by: { $0.frenchName < $1.frenchName })
        } else {
            newCityList.sort(by: { $0.englishName < $1.englishName })
        }
        
        return newCityList
    }
    
    static func getCurrentLocationCity() -> City {
        let currentLocation = City()
        currentLocation.englishName = "Use Current Location"
        currentLocation.frenchName = "Utiliser la géolocalisation"
        currentLocation.id = Global.currentLocationCityId
        
        return currentLocation
    }
}
