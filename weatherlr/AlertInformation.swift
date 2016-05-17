//
//  AlertInformation.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-08.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

class AlertInformation{
    var alertText:String
    var url:String
    var type:AlertType
    
    init() {
        alertText = ""
        url = ""
        type = AlertType.None
    }
    
    init(alertText: String, url: String, type:AlertType) {
        self.alertText = alertText
        self.url = url
        self.type = type
    }
}