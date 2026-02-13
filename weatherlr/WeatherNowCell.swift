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
                        weatherImage.image = weatherInfo.image()
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

    private func showPrecipitationChart(with data: [(minuteOffset: Int, intensity: Double)]) {
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
        precipitationChartView?.configure(with: data)
        precipitationChartView?.isHidden = false
    }

    private func hidePrecipitationChart() {
        precipitationChartView?.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        weatherImage.isHidden = true
        hidePrecipitationChart()
    }
}
