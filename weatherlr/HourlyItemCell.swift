//
//  HourlyItemCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

#if ENABLE_WEATHERKIT
import UIKit
import WeatherKit

class HourlyItemCell: UICollectionViewCell {
    static let reuseIdentifier = "HourlyItemCell"

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let precipLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()

    private let tempLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .center
        sv.spacing = 4
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        stackView.addArrangedSubview(timeLabel)
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(precipLabel)
        stackView.addArrangedSubview(tempLabel)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with hourWeather: HourWeather, isCurrentHour: Bool) {
        if isCurrentHour {
            timeLabel.text = "Now".localized()
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH"
            timeLabel.text = formatter.string(from: hourWeather.date) + "h"
        }

        iconImageView.image = WeatherHelper.image(for: hourWeather.condition, night: !hourWeather.isDaylight)

        let precipChance = Int(hourWeather.precipitationChance * 100)
        if precipChance > 0 {
            precipLabel.text = "\(precipChance)%"
            precipLabel.isHidden = false
        } else {
            precipLabel.text = nil
            precipLabel.isHidden = true
        }

        let temp = Int(hourWeather.temperature.value.rounded())
        tempLabel.text = "\(temp)°"
    }
}
#endif
