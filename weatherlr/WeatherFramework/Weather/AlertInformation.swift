//
//  AlertInformation.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

public class AlertInformation{
    public var alertText:String
    public var url:String
    public var type:AlertType
    public var eventIssueTime:String
    public var expiryTime:String
    public var alertColourLevel:String

    public init() {
        alertText = ""
        url = ""
        type = AlertType.none
        eventIssueTime = ""
        expiryTime = ""
        alertColourLevel = ""
    }

    public init(alertText: String, url: String, type:AlertType) {
        self.alertText = alertText
        self.url = url
        self.type = type
        self.eventIssueTime = ""
        self.expiryTime = ""
        self.alertColourLevel = ""
    }

    public init(alertText: String, url: String, type: AlertType, eventIssueTime: String, expiryTime: String, alertColourLevel: String) {
        self.alertText = alertText
        self.url = url
        self.type = type
        self.eventIssueTime = eventIssueTime
        self.expiryTime = expiryTime
        self.alertColourLevel = alertColourLevel
    }
}
