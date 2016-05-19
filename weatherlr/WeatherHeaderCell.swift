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
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func populate(city:City, weatherInformationWrapper: WeatherInformationWrapper) {
        var name = city.englishName
        if PreferenceHelper.isFrench() {
            name = city.frenchName
        }
        cityLabel.text = name
        
        if weatherInformationWrapper.weatherInformations.count > 0 {
            var weatherInfo = weatherInformationWrapper.weatherInformations[0]
            
            if weatherInfo.weatherDay == WeatherDay.Now {
                currentTemperatureLabel.hidden = false
                currentTemperatureLabel.text = String(weatherInfo.temperature)
                
                if(weatherInfo.weatherStatus == .Blank) {
                    weatherImage.hidden = true
                } else {
                    weatherImage.image = weatherInfo.image()
                    weatherImage.hidden = false
                }
                
                if weatherInformationWrapper.weatherInformations.count > 1 {
                    weatherInfo = weatherInformationWrapper.weatherInformations[1]
                    
                    temperatureLabel.hidden = false
                    temperatureImage.hidden = false
                    temperatureLabel.text = String(weatherInfo.temperature)
                    temperatureImage.image = WeatherHelper.getMinMaxImage(weatherInfo, header: true)
                } else {
                    temperatureLabel.text = ""
                    temperatureLabel.hidden = true
                    temperatureImage.hidden = true
                }
            } else {
                temperatureLabel.hidden = true
                temperatureImage.hidden = true
                weatherImage.hidden = true
                currentTemperatureLabel.hidden = true
            }
        }
    }
    
    func gradientBackground(color: UIColor) {
        let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
        gradientMaskLayer.frame = bounds
        gradientMaskLayer.colors = [color.colorWithAlphaComponent(0.95).CGColor, color.colorWithAlphaComponent(0)]
        gradientMaskLayer.locations = [0.70, 1.0]
        layer.mask = gradientMaskLayer
        backgroundColor = color.colorWithAlphaComponent(0.95)
    }
}
