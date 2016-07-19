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
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var currentTemperatureLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var temperatureImage: UIImageView!
    
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
            var weatherInfo = weatherInformationWrapper.weatherInformations[0]
            
            if weatherInfo.weatherDay == WeatherDay.now {
                currentTemperatureLabel.isHidden = false
                currentTemperatureLabel.text = String(weatherInfo.temperature)
                
                if(weatherInfo.weatherStatus == .blank) {
                    weatherImage.isHidden = true
                } else {
                    weatherImage.image = weatherInfo.image()
                    weatherImage.isHidden = false
                }
                
                if weatherInformationWrapper.weatherInformations.count > 1 {
                    weatherInfo = weatherInformationWrapper.weatherInformations[1]
                    
                    temperatureLabel.isHidden = false
                    temperatureImage.isHidden = false
                    temperatureLabel.text = String(weatherInfo.temperature)
                    temperatureImage.image = WeatherHelper.getMinMaxImage(weatherInfo, header: true)
                } else {
                    temperatureLabel.text = ""
                    temperatureLabel.isHidden = true
                    temperatureImage.isHidden = true
                }
            } else {
                temperatureLabel.isHidden = true
                temperatureImage.isHidden = true
                weatherImage.isHidden = true
                currentTemperatureLabel.isHidden = true
            }
        }
    }
    
    func gradientBackground(_ color: UIColor) {
        let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
        gradientMaskLayer.frame = bounds
        gradientMaskLayer.colors = [color.withAlphaComponent(0.95).cgColor, color.withAlphaComponent(0)]
        gradientMaskLayer.locations = [0.70, 1.0]
        layer.mask = gradientMaskLayer
        backgroundColor = color.withAlphaComponent(0.95)
    }
}
