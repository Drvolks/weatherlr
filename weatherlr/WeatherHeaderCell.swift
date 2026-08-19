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

    /// The weather screen paints its own solid background and every surface on
    /// top of it must be fully transparent. Clearing `backgroundColor` alone is
    /// not enough: a cell also renders `backgroundView` and, on iOS 14+, a
    /// `backgroundConfiguration` that takes precedence over both. iOS 27 draws a
    /// light panel behind this header when those are left at their defaults
    /// (#33), so pin all of them to transparent and opt out of the automatic
    /// configuration updates that would otherwise restore a default background.
    private func makeTransparent() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        backgroundView = nil
        selectedBackgroundView = nil
        automaticallyUpdatesBackgroundConfiguration = false
        backgroundConfiguration = .clear()
        selectionStyle = .none
    }

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

        makeTransparent()
    }

    #if ENABLE_PWS
    /// - Parameter prefersStationName: when true the station name labels the
    ///   header instead of the city — only for "use current location", where the
    ///   user has not named a city of their own (#34).
    func initialize(city: City?, weatherInformationWrapper: WeatherInformationWrapper, pwsStationName: String? = nil, pwsTemperature: Int? = nil, prefersStationName: Bool = false) {
        if let city = city {
            populate(city: city, weatherInformationWrapper: weatherInformationWrapper, pwsStationName: pwsStationName, pwsTemperature: pwsTemperature, prefersStationName: prefersStationName)
        }

        makeTransparent()
    }

    private func populate(city: City, weatherInformationWrapper: WeatherInformationWrapper, pwsStationName: String?, pwsTemperature: Int?, prefersStationName: Bool) {
        if LocationServices.isUseCurrentLocation(city) {
            temperatureLabel.text = ""
            cityLabel.text = "Locating".localized()
        } else {
            if weatherInformationWrapper.weatherInformations.count > 0 {
                let weatherInfo = weatherInformationWrapper.weatherInformations[0]

                if weatherInfo.weatherDay == WeatherDay.now {
                    // A city the user chose is never replaced by the station
                    // name (#34); the sensor icon alone marks the reading as
                    // coming from a personal station. Only when the city itself
                    // was derived from the current location does the station
                    // name — the more precise of the two — label the header.
                    if let pwsTemp = pwsTemperature {
                        temperatureLabel.text = String(pwsTemp) + "°"
                        let name = (prefersStationName ? pwsStationName : nil) ?? CityHelper.cityName(city)
                        setCityWithStationIcon(name, stationName: pwsStationName)
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
        if let stationName = stationName, stationName != cityName {
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

        makeTransparent()
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
