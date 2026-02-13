//
//  AlertInformation.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-08.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

public class AlertInformation{
    public var alertText:String
    public var url:String
    public var type:AlertType
    
    public init() {
        alertText = ""
        url = ""
        type = AlertType.none
    }
    
    public init(alertText: String, url: String, type:AlertType) {
        self.alertText = alertText
        self.url = url
        self.type = type
    }
}
