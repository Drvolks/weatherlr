//
//  QuickActionsHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 16-10-30.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class PhonePreferenceHelper : PreferenceHelper {
    override func addFavorite(_ city: City) {
        super.addFavorite(city)
        
        var shortcutItems = [UIApplicationShortcutItem]()
        let cities = PhonePreferenceHelper.getFavoriteCities()
        
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
    }
}
