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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func populate(_ city:City, weatherInformationWrapper: WeatherInformationWrapper) {
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
