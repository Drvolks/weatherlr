//
//  WatchHourlyRow.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2026-03-19.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import SwiftUI

struct WatchHourlyRow: View {
    let hourlyForecasts: [HourlyForecastInfo]

    private var next3Hours: [HourlyForecastInfo] {
        Array(hourlyForecasts.prefix(3))
    }

    var body: some View {
        NavigationLink(destination: WatchHourlyDetailView(hourlyForecasts: hourlyForecasts)) {
            HStack(spacing: 0) {
                ForEach(Array(next3Hours.enumerated()), id: \.offset) { _, hourly in
                    VStack(spacing: 2) {
                        Text(hourLabel(for: hourly))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))

                        Image(uiImage: hourlyImage(hourly))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)

                        if hourly.precipChance > 0 {
                            Text("\(hourly.precipChance)%")
                                .font(.system(size: 9))
                                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
                        }

                        Text("\(hourly.temperature)°")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(5)
        .background(Color.white.opacity(0.15))
        .cornerRadius(8)
    }

    private func hourLabel(for hourly: HourlyForecastInfo) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        return formatter.string(from: hourly.date) + "h"
    }

    private func hourlyImage(_ hourly: HourlyForecastInfo) -> UIImage {
        if let name = WeatherHelper.imageNameForIconCode(hourly.iconCode ?? -1),
           let image = UIImage(named: name) {
            return image
        }
        return UIImage(named: "na") ?? UIImage()
    }
}
