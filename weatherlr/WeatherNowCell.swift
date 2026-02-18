//
//  WeatherNowCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 17-12-28.
//  Copyright © 2017 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherNowCell: UITableViewCell {
    @IBOutlet weak var weatherImage: UIImageView!

    #if ENABLE_WEATHERKIT
    private var precipitationChartView: PrecipitationChartView?

    func initialize(city: City?, weatherInformationWrapper: WeatherInformationWrapper, weatherKitData: WeatherKitData? = nil) {
        if let city = city {
            populate(city: city, weatherInformationWrapper: weatherInformationWrapper, weatherKitData: weatherKitData)
        }

        separatorInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
    }

    private func populate(city: City, weatherInformationWrapper: WeatherInformationWrapper, weatherKitData: WeatherKitData?) {
        if LocationServices.isUseCurrentLocation(city) {
            weatherImage.isHidden = false
            weatherImage.image = UIImage(named: "locating")
            hidePrecipitationChart()
        } else {
            if weatherInformationWrapper.weatherInformations.count > 0 {
                let weatherInfo = weatherInformationWrapper.weatherInformations[0]

                if weatherInfo.weatherDay == WeatherDay.now {
                    if weatherInfo.weatherStatus == .blank {
                        weatherImage.isHidden = true
                        hidePrecipitationChart()
                    } else if let data = weatherKitData, data.hasPrecipitationNextHour {
                        weatherImage.isHidden = true
                        showPrecipitationChart(with: data.precipitationMinutes)
                    } else {
                        if let data = weatherKitData {
                            weatherImage.image = WeatherHelper.image(for: data.currentWeather.condition, night: !data.isDaylight())
                        } else {
                            weatherImage.image = weatherInfo.image()
                        }
                        weatherImage.isHidden = false
                        hidePrecipitationChart()
                    }
                } else {
                    weatherImage.isHidden = true
                    hidePrecipitationChart()
                }
            }
        }
    }

    func transitionToPrecipitation(with data: [(minuteOffset: Int, intensity: Double)]) {
        ensureChartView()
        precipitationChartView?.configure(with: data)
        precipitationChartView?.alpha = 0
        precipitationChartView?.isHidden = false

        UIView.animate(withDuration: 0.5) {
            self.weatherImage.alpha = 0
            self.precipitationChartView?.alpha = 1
        } completion: { _ in
            self.weatherImage.isHidden = true
            self.weatherImage.alpha = 1
        }
    }

    private func showPrecipitationChart(with data: [(minuteOffset: Int, intensity: Double)]) {
        ensureChartView()
        precipitationChartView?.configure(with: data)
        precipitationChartView?.alpha = 1
        precipitationChartView?.isHidden = false
    }

    private func ensureChartView() {
        if precipitationChartView == nil {
            let chart = PrecipitationChartView()
            chart.backgroundColor = .clear
            chart.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(chart)
            NSLayoutConstraint.activate([
                chart.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                chart.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                chart.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                chart.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
            ])
            precipitationChartView = chart
        }
    }

    private func hidePrecipitationChart() {
        precipitationChartView?.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        weatherImage.isHidden = true
        weatherImage.alpha = 1
        hidePrecipitationChart()
    }
    #else
    func initialize(city: City?, weatherInformationWrapper: WeatherInformationWrapper) {
        if let city = city {
            populate(city: city, weatherInformationWrapper: weatherInformationWrapper)
        }

        separatorInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
    }

    private func populate(city: City, weatherInformationWrapper: WeatherInformationWrapper) {
        if LocationServices.isUseCurrentLocation(city) {
            weatherImage.isHidden = false
            weatherImage.image = UIImage(named: "locating")
        } else {
            if weatherInformationWrapper.weatherInformations.count > 0 {
                let weatherInfo = weatherInformationWrapper.weatherInformations[0]

                if weatherInfo.weatherDay == WeatherDay.now {
                    if weatherInfo.weatherStatus == .blank {
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

    override func prepareForReuse() {
        super.prepareForReuse()
        weatherImage.isHidden = true
    }
    #endif
}
