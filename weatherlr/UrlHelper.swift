//
//  UrlHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class UrlHelper {
    static func getUrl(city: City) -> String {
        let url = "url".localized().stringByReplacingOccurrencesOfString("{id}", withString: city.id)
        
        return url
    }
    
    static func getUrl(city: City, lang: Language) -> String {
        let url = "url".localized(lang).stringByReplacingOccurrencesOfString("{id}", withString: city.id)
        
        return url
    }
    
    static func getRadarUrl(city: City) -> String {
        let url = "radarUrl".localized().stringByReplacingOccurrencesOfString("{id}", withString: city.radarId)
        
        return url
    }
}