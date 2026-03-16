//
//  HourlyForecastInfo.swift
//  weatherlr
//
//  Created by drvolks on 2026-03-16.
//  Copyright © 2026 drvolks. All rights reserved.
//

import Foundation

public struct HourlyForecastInfo {
    public let date: Date
    public let temperature: Int
    public let iconCode: Int?
    public let precipChance: Int

    public var night: Bool {
        guard let code = iconCode else {
            let hour = Calendar.current.component(.hour, from: date)
            return hour < 7 || hour >= 19
        }
        return code >= 30 && code <= 39
    }

    public var imageName: String {
        if let code = iconCode, let name = WeatherHelper.imageNameForIconCode(code) {
            return name
        }
        return "na"
    }
}
