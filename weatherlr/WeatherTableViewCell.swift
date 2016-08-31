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
        let indexAjust = WeatherHelper.getIndexAjust(weatherInformationWrapper.weatherInformations)
        
        let weatherInfo = weatherInformationWrapper.weatherInformations[(indexPath as NSIndexPath).row+indexAjust]
        weatherImage.image = weatherInfo.image()
        weatherDetailLabel.text = weatherInfo.detail
        whenLabel.text = WeatherHelper.getWeatherDayWhenText(weatherInfo)
        backgroundColor = UIColor.clear
        
        if weatherInfo.weatherDay == WeatherDay.today && weatherInformationWrapper.weatherInformations[0].weatherDay == .now {
            minMaxLabel.isHidden = true
            minMaxImage.isHidden = true
        } else {
            minMaxLabel.text = String(weatherInfo.temperature)
            minMaxImage.image = WeatherHelper.getMinMaxImage(weatherInfo, header: false)
            
            minMaxLabel.isHidden = false
            minMaxImage.isHidden = false
        }
    }
}
