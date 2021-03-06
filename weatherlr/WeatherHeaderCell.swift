//
//  WeatherHeaderCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-09.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit
import WeatherFramework

class WeatherHeaderCell: UITableViewCell {
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    func initialize(city: City?, weatherInformationWrapper: WeatherInformationWrapper) {
        if let city = city {
            populate(city: city, weatherInformationWrapper: weatherInformationWrapper)
        }
        
        backgroundColor = UIColor.clear
    }
    
    private func populate(city:City, weatherInformationWrapper: WeatherInformationWrapper) {
        if LocationServices.isUseCurrentLocation(city) {
            temperatureLabel.text = ""
            cityLabel.text = "Locating".localized()
        } else {
            if weatherInformationWrapper.weatherInformations.count > 0 {
                let weatherInfo = weatherInformationWrapper.weatherInformations[0]
                
                if weatherInfo.weatherDay == WeatherDay.now {
                    cityLabel.text = CityHelper.cityName(city)
                    temperatureLabel.text = String(weatherInfo.temperature) + "°"
                    return
                }
            }
            
            temperatureLabel.text = ""
            cityLabel.text = CityHelper.cityName(city)
        }
    }
}
