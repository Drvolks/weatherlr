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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func populate(_ city:City, weatherInformationWrapper: WeatherInformationWrapper) {
        cityLabel.text = CityHelper.cityName(city)
        
        if weatherInformationWrapper.weatherInformations.count > 0 {
            let weatherInfo = weatherInformationWrapper.weatherInformations[0]
            
            if weatherInfo.weatherDay == WeatherDay.now {
                cityLabel.text = CityHelper.cityName(city) + " " + String(weatherInfo.temperature) + "°"
            }
        }
    }
}
