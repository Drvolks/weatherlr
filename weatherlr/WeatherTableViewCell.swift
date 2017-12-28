//
//  WeatherTableViewCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-06.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherTableViewCell: UITableViewCell {
    @IBOutlet weak var weatherDetailLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var whenLabel: UILabel!
    @IBOutlet weak var minMaxLabel: UILabel!
    @IBOutlet weak var minMaxImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func populate(_ weatherInformationWrapper: WeatherInformationWrapper, indexPath: IndexPath) {
        let weatherInfo = weatherInformationWrapper.weatherInformations[(indexPath as NSIndexPath).row]
        weatherImage.image = weatherInfo.image()
        weatherDetailLabel.text = weatherInfo.detail
        whenLabel.text = WeatherHelper.getWeatherDayWhenText(weatherInfo)
        backgroundColor = UIColor.clear
        
        if weatherInfo.weatherDay == WeatherDay.today && weatherInformationWrapper.weatherInformations[0].weatherDay == .now {
            var minMax = "Maximum".localized()
            if weatherInfo.tendancy == Tendency.minimum {
                minMax = "Minimum".localized()
            } else if weatherInfo.tendancy == Tendency.steady {
                if weatherInfo.night {
                    minMax = "Stable".localized()
                }
            }
            
            whenLabel.text = WeatherHelper.getWeatherDayWhenText(weatherInfo) + " " + minMax + " " + String(weatherInfo.temperature) + "°"
            whenLabel.font = UIFont.boldSystemFont(ofSize: 20)
            
            minMaxLabel.isHidden = true
            minMaxImage.isHidden = true
        } else {
            whenLabel.font = UIFont.boldSystemFont(ofSize: 15)
            minMaxLabel.text = String(weatherInfo.temperature)
            minMaxImage.image = WeatherHelper.getMinMaxImage(weatherInfo, header: false)
            
            minMaxLabel.isHidden = false
            minMaxImage.isHidden = false
        }
    }
}
