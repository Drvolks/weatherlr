//
//  HourlyForecastCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

#if ENABLE_WEATHERKIT
import UIKit
import WeatherKit

class HourlyForecastCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    static let reuseIdentifier = "HourlyForecastCell"

    private var hours: [HourWeather] = []
    private var isLoading = true
    private var collectionView: UICollectionView!
    private var loadingLabel: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)

        // Loading placeholder
        loadingLabel = UILabel()
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.text = "Hourly Loading".localized()
        loadingLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        loadingLabel.font = .systemFont(ofSize: 14, weight: .medium)
        loadingLabel.textAlignment = .center
        contentView.addSubview(loadingLabel)
        NSLayoutConstraint.activate([
            loadingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            loadingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            loadingLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        // Collection view
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 100)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HourlyItemCell.self, forCellWithReuseIdentifier: HourlyItemCell.reuseIdentifier)

        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with weatherKitData: WeatherKitData?) {
        if let data = weatherKitData {
            self.hours = data.next24Hours
            self.isLoading = false
        } else {
            self.hours = []
            self.isLoading = true
        }
        loadingLabel.isHidden = !isLoading
        collectionView.isHidden = isLoading
        collectionView.reloadData()
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hours.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HourlyItemCell.reuseIdentifier, for: indexPath) as! HourlyItemCell
        let hour = hours[indexPath.item]
        cell.configure(with: hour, isCurrentHour: indexPath.item == 0)
        return cell
    }
}
#endif
