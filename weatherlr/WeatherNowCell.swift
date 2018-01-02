//
//  WeatherNowCell.swift
//  weatherlr
//
//  Created by drvolks on 17-12-28.
//  Copyright © 2017 drvolks. All rights reserved.
//

import UIKit

class WeatherNowCell: UITableViewCell {
    @IBOutlet weak var weatherImage: UIImageView!
    
    func initialize(city: City?, weatherInformationWrapper: WeatherInformationWrapper) {
        if let city = city {
            populate(city: city, weatherInformationWrapper: weatherInformationWrapper)
        }
        
        separatorInset = UIEdgeInsetsMake(0, 0, 0, UIScreen.main.bounds.width)
    }
    
    private func populate(city:City, weatherInformationWrapper: WeatherInformationWrapper) {
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
