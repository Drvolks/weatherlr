//
//  UrlHelper.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-08.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

class UrlHelper {
    static func getUrl(city: City) -> String {
        // TODO bilingue
        let url = Constants.baseUrlFrench.stringByReplacingOccurrencesOfString("{id}", withString: city.id)
        
        return url
    }
}