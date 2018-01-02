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
        minMaxLabel.text = WeatherHelper.getWeatherTextWithMinMax(weatherInfo)
        
        if weatherInfo.weatherDay == WeatherDay.today && weatherInformationWrapper.weatherInformations[0].weatherDay == .now {
            whenLabel.font = UIFont.boldSystemFont(ofSize: 25)
            minMaxLabel.font = UIFont.systemFont(ofSize: 23)
        } else {
            whenLabel.font = UIFont.boldSystemFont(ofSize: 17)
            minMaxLabel.font = UIFont.systemFont(ofSize: 15)
        }
    }
}
