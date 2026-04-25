//
//  HourlyForecastCell.swift
//  weatherlr
//
//  Created by drvolks on 2025-02-13.
//  Copyright © 2025 drvolks. All rights reserved.
//

import UIKit

class HourlyForecastCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    static let reuseIdentifier = "HourlyForecastCell"

    private var hours: [HourlyForecastInfo] = []
    private var collectionView: UICollectionView!

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

    func configure(with hourlyForecasts: [HourlyForecastInfo]) {
        self.hours = hourlyForecasts
        collectionView.isHidden = hours.isEmpty
        collectionView.reloadData()
        resetScrollPosition()
    }

    private func resetScrollPosition() {
        collectionView.setContentOffset(.zero, animated: false)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hours.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HourlyItemCell.reuseIdentifier, for: indexPath) as? HourlyItemCell else {
            assertionFailure("Expected \(HourlyItemCell.reuseIdentifier) to be a HourlyItemCell")
            return UICollectionViewCell()
        }
        let hour = hours[indexPath.item]
        cell.configure(with: hour, isCurrentHour: indexPath.item == 0)
        return cell
    }
}
