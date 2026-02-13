//
//  PWSObservation.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

import Foundation

struct WUResponse: Codable {
    let observations: [WUObservation]?
}

struct WUObservation: Codable {
    let stationID: String
    let obsTimeUtc: String?
    let obsTimeLocal: String?
    let neighborhood: String?
    let lat: Double
    let lon: Double
    let humidity: Int?
    let winddir: Int?
    let imperial: WUImperial?

    var tempC: Double? {
        guard let tempF = imperial?.temp else { return nil }
        return (tempF - 32.0) * 5.0 / 9.0
    }

    var windChillC: Double? {
        guard let wcF = imperial?.windChill else { return nil }
        return (wcF - 32.0) * 5.0 / 9.0
    }
}

struct WUImperial: Codable {
    let temp: Double?
    let heatIndex: Double?
    let dewpt: Double?
    let windChill: Double?
    let windSpeed: Double?
    let windGust: Double?
    let pressure: Double?
    let precipRate: Double?
    let precipTotal: Double?
    let elev: Double?
}
