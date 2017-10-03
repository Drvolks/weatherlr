//
//  AlertInformation.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class AlertInformation{
    var alertText:String
    var url:String
    var type:AlertType
    
    init() {
        alertText = ""
        url = ""
        type = AlertType.none
    }
    
    init(alertText: String, url: String, type:AlertType) {
        self.alertText = alertText
        self.url = url
        self.type = type
    }
}
