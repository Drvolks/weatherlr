//
//  PWSStation.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

#if ENABLE_PWS
import Foundation

public struct PWSStation: Codable {
    public var stationId: String
    public var name: String
    public var latitude: Double
    public var longitude: Double
}
#endif
