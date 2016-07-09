//
//  CityHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-09.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class CityHelper {
    static func searchCity(searchText: String, allCityList: [City]) -> [City] {
        var newFilteredList = [City]()
        
        for i in 0..<allCityList.count {
            let city = allCityList[i]
            
            let name = cityNameForSearch(city)
            
            let searched = searchText.uppercaseString.stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale(localeIdentifier: "en"))
            
            if name.containsString(searched) {
                newFilteredList.append(city)
            }
        }
        
        return newFilteredList
    }
    
    static func searchCityStartingWith(searchText: String, allCityList: [City]) -> [City] {
        var newFilteredList = [City]()
        
        for i in 0..<allCityList.count {
            let city = allCityList[i]
            
            let name = cityNameForSearch(city)
            
            if name.uppercaseString.hasPrefix(searchText) {
                newFilteredList.append(city)
            }
        }
        
        return newFilteredList
    }
    
    static func searchSingleCity(searchText: String, allCityList: [City]) -> City? {
        let result = searchCity(searchText, allCityList: allCityList)
        if result.count > 0 {
            return result[0]
        }
        
        return nil
    }
    
    
    static func cityNameForSearch(city: City) -> String {
        var name = city.englishName
        if(PreferenceHelper.isFrench()) {
            name = city.frenchName
        }
        
        name = name.uppercaseString.stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale(localeIdentifier: "en"))
        
        return name
    }
    
    static func cityName(city:City) -> String {
        var name = city.englishName
        if(PreferenceHelper.isFrench()) {
            name = city.frenchName
        }
        
        return name;
    }
    
    static func sortCityList(cityListToSort: [City]) -> [City] {
        var newCityList = cityListToSort
        
        if PreferenceHelper.isFrench() {
            newCityList.sortInPlace({ $0.frenchName < $1.frenchName })
        } else {
            newCityList.sortInPlace({ $0.englishName < $1.englishName })
        }
        
        return newCityList
    }
}