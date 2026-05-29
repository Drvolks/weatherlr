//
//  AlertInformation.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-08.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

public class AlertInformation{
    public var alertText:String          // headline (e.g. "Severe thunderstorm warning")
    public var alertDetails:String       // full warning body, when the source provides one
    public var url:String
    public var type:AlertType
    public var eventIssueTime:String
    public var expiryTime:String
    public var alertColourLevel:String

    public init() {
        alertText = ""
        alertDetails = ""
        url = ""
        type = AlertType.none
        eventIssueTime = ""
        expiryTime = ""
        alertColourLevel = ""
    }

    public init(alertText: String, url: String, type:AlertType, alertDetails: String = "") {
        self.alertText = alertText
        self.alertDetails = alertDetails
        self.url = url
        self.type = type
        self.eventIssueTime = ""
        self.expiryTime = ""
        self.alertColourLevel = ""
    }

    public init(alertText: String, url: String, type: AlertType, eventIssueTime: String, expiryTime: String, alertColourLevel: String, alertDetails: String = "") {
        self.alertText = alertText
        self.alertDetails = alertDetails
        self.url = url
        self.type = type
        self.eventIssueTime = eventIssueTime
        self.expiryTime = expiryTime
        self.alertColourLevel = alertColourLevel
    }
}
