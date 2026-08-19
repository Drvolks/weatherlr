//
//  WeatherHeaderCell.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-09.
//  Copyright © 2016 drvolks. All rights reserved.
//

import UIKit

class WeatherHeaderCell: UITableViewCell {
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()

        // `initialize` re-sets both labels on every dequeue, so this is
        // belt-and-braces — but it also clears the attributed text and
        // accessibility label left by the PWS sensor-icon path, which the plain
        // `cityLabel.text = …` assignment on the next pass would not.
        cityLabel.attributedText = nil
        cityLabel.text = nil
        cityLabel.accessibilityLabel = nil
        temperatureLabel.text = nil
    }

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
                    // The label always names the selected city. When the
                    // temperature comes from a personal weather station, that is
                    // indicated with the sensor icon only — the station name must
                    // never replace the city name (#34).
                    if let pwsTemp = pwsTemperature {
                        temperatureLabel.text = String(pwsTemp) + "°"
                        setCityWithStationIcon(CityHelper.cityName(city), stationName: pwsStationName)
                    } else {
                        temperatureLabel.text = String(weatherInfo.temperature) + "°"
                        cityLabel.text = CityHelper.cityName(city)
                    }

                    return
                }
            }

            temperatureLabel.text = ""
            cityLabel.text = CityHelper.cityName(city)
        }
    }

    private func setCityWithStationIcon(_ cityName: String, stationName: String?) {
        // Keep the station out of the visible label but not out of VoiceOver:
        // the icon alone doesn't say where the reading came from.
        if let stationName = stationName {
            cityLabel.accessibilityLabel = cityName + ", " + stationName
        } else {
            cityLabel.accessibilityLabel = nil
        }

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
