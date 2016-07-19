//
//  UrlHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class UrlHelper {
    static func getUrl(_ city: City) -> String {
        let url = "url".localized().replacingOccurrences(of: "{id}", with: city.id)
        
        return url
    }
    
    static func getUrl(_ city: City, lang: Language) -> String {
        let url = "url".localized(lang).replacingOccurrences(of: "{id}", with: city.id)
        
        return url
    }
    
    static func getRadarUrl(_ city: City) -> String {
        let url = "radarUrl".localized().replacingOccurrences(of: "{id}", with: city.radarId)
        
        return url
    }
}
