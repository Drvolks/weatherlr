//
//  UIColorExtension.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-20.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit
import WeatherFramework

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(weatherColor:WeatherColor) {
        self.init(red:(weatherColor.rawValue >> 16) & 0xff, green:(weatherColor.rawValue >> 8) & 0xff, blue:weatherColor.rawValue & 0xff)
    }
}
