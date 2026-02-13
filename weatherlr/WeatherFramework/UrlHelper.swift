//
//  UrlHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

public class UrlHelper {
    public static func getUrl(_ city: City) -> String {
        return "https://api.weather.gc.ca/collections/citypageweather-realtime/items/\(city.id)?f=json"
    }

    public static func getUrl(_ city: City, lang: Language) -> String {
        let langParam = lang == .French ? "fr-CA" : "en-CA"
        return "https://api.weather.gc.ca/collections/citypageweather-realtime/items/\(city.id)?f=json&lang=\(langParam)"
    }
    
    public static func getRadarUrl(_ city: City) -> String {
        let url = "radarUrl".localized().replacingOccurrences(of: "{longitude}", with: city.longitude).replacingOccurrences(of: "{latitude}", with: city.latitude)
        
        return url
    }
}
