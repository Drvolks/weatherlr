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
    
    init() {
        alertText = ""
        url = ""
    }
    
    init(alertText: String, url: String) {
        self.alertText = alertText
        self.url = url
    }
}