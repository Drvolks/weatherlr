//
//  WeatherHeaderCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-09.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherHeaderCell: UITableViewCell {
    @IBOutlet weak var cityLabel: VerticalTopAlignLabel!
    
    func initialize(city: City?, weatherInformationWrapper: WeatherInformationWrapper) {
        if let city = city {
            populate(city: city, weatherInformationWrapper: weatherInformationWrapper)
        }
        
        backgroundColor = UIColor.clear
    }
    
    private func populate(city:City, weatherInformationWrapper: WeatherInformationWrapper) {
        cityLabel.text = CityHelper.cityName(city)
        
        if weatherInformationWrapper.weatherInformations.count > 0 {
            let weatherInfo = weatherInformationWrapper.weatherInformations[0]
            
            if weatherInfo.weatherDay == WeatherDay.now {
                cityLabel.text = CityHelper.cityName(city) + " " + String(weatherInfo.temperature) + "°"
            }
        }
    }
}
