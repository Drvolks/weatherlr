//
//  WeatherHeaderCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-09.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherHeaderCell: UITableViewCell {
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    #if ENABLE_PWS
    func initialize(city: City?, weatherInformationWrapper: WeatherInformationWrapper, pwsStationName: String? = nil, pwsTemperature: Int? = nil) {
        if let city = city {
            populate(city: city, weatherInformationWrapper: weatherInformationWrapper, pwsStationName: pwsStationName, pwsTemperature: pwsTemperature)
        }

        backgroundColor = UIColor.clear
    }

    private func populate(city: City, weatherInformationWrapper: WeatherInformationWrapper, pwsStationName: String?, pwsTemperature: Int?) {
        if LocationServices.isUseCurrentLocation(city) {
            temperatureLabel.text = ""
            cityLabel.text = "Locating".localized()
        } else {
            if weatherInformationWrapper.weatherInformations.count > 0 {
                let weatherInfo = weatherInformationWrapper.weatherInformations[0]

                if weatherInfo.weatherDay == WeatherDay.now {
                    if let pwsTemp = pwsTemperature {
                        temperatureLabel.text = String(pwsTemp) + "°"
                        setCityWithStationIcon(pwsStationName ?? CityHelper.cityName(city))
                    } else {
                        temperatureLabel.text = String(weatherInfo.temperature) + "°"
                        if let stationName = pwsStationName {
                            setCityWithStationIcon(stationName)
                        } else {
                            cityLabel.text = CityHelper.cityName(city)
                        }
                    }

                    return
                }
            }

            temperatureLabel.text = ""
            cityLabel.text = CityHelper.cityName(city)
        }
    }

    private func setCityWithStationIcon(_ cityName: String) {
        let fontSize = cityLabel.font.pointSize
        let config = UIImage.SymbolConfiguration(pointSize: fontSize * 0.35, weight: .medium)
        guard let icon = UIImage(systemName: "sensor.fill", withConfiguration: config)?.withTintColor(UIColor.white.withAlphaComponent(0.7), renderingMode: .alwaysOriginal) else {
            cityLabel.text = cityName
            return
        }

        let attachment = NSTextAttachment()
        attachment.image = icon
        let iconHeight = icon.size.height
        let capHeight = cityLabel.font.capHeight
        attachment.bounds = CGRect(x: 0, y: capHeight - iconHeight, width: icon.size.width, height: iconHeight)

        let attributed = NSMutableAttributedString(string: cityName + " ", attributes: [
            .font: cityLabel.font!,
            .foregroundColor: cityLabel.textColor!
        ])
        attributed.append(NSAttributedString(attachment: attachment))
        cityLabel.attributedText = attributed
    }
    #else
    func initialize(city: City?, weatherInformationWrapper: WeatherInformationWrapper) {
        if let city = city {
            populate(city: city, weatherInformationWrapper: weatherInformationWrapper)
        }

        backgroundColor = UIColor.clear
    }

    private func populate(city: City, weatherInformationWrapper: WeatherInformationWrapper) {
        if LocationServices.isUseCurrentLocation(city) {
            temperatureLabel.text = ""
            cityLabel.text = "Locating".localized()
        } else {
            if weatherInformationWrapper.weatherInformations.count > 0 {
                let weatherInfo = weatherInformationWrapper.weatherInformations[0]

                if weatherInfo.weatherDay == WeatherDay.now {
                    temperatureLabel.text = String(weatherInfo.temperature) + "°"
                    cityLabel.text = CityHelper.cityName(city)
                    return
                }
            }

            temperatureLabel.text = ""
            cityLabel.text = CityHelper.cityName(city)
        }
    }
    #endif
}
