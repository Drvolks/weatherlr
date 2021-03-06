//
//  WeatherNowCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 17-12-28.
//  Copyright © 2017 Jean-Francois Dufour. All rights reserved.
//

import UIKit
import WeatherFramework

class WeatherNowCell: UITableViewCell {
    @IBOutlet weak var weatherImage: UIImageView!
    
    func initialize(city: City?, weatherInformationWrapper: WeatherInformationWrapper) {
        if let city = city {
            populate(city: city, weatherInformationWrapper: weatherInformationWrapper)
        }
        
        separatorInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
    }
    
    private func populate(city:City, weatherInformationWrapper: WeatherInformationWrapper) {
        if LocationServices.isUseCurrentLocation(city) {
            weatherImage.isHidden = false
            weatherImage.image = UIImage(named: "locating")
        } else {
            if weatherInformationWrapper.weatherInformations.count > 0 {
                let weatherInfo = weatherInformationWrapper.weatherInformations[0]
                
                if weatherInfo.weatherDay == WeatherDay.now {
                    if(weatherInfo.weatherStatus == .blank) {
                        weatherImage.isHidden = true
                    } else {
                        weatherImage.image = weatherInfo.image()
                        weatherImage.isHidden = false
                    }
                } else {
                    weatherImage.isHidden = true
                }
            }
        }
    }
}
