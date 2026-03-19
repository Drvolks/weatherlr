//
//  WatchHourlyDetailView.swift
//  watch Extension
//
//  Created by drvolks on 2026-03-19.
//  Copyright © 2026 drvolks. All rights reserved.
//

import SwiftUI

struct WatchHourlyDetailView: View {
    let hourlyForecasts: [HourlyForecastInfo]

    private enum Row: Identifiable {
        case dateHeader(String, Int)
        case hourly(HourlyForecastInfo, Int)

        var id: Int {
            switch self {
            case .dateHeader(_, let i): return i
            case .hourly(_, let i): return i
            }
        }
    }

    private var rows: [Row] {
        let calendar = Calendar.current
        var result = [Row]()
        var currentDayStart: Date? = nil
        var idCounter = 0

        for hourly in hourlyForecasts {
            let dayStart = calendar.startOfDay(for: hourly.date)
            if let prev = currentDayStart, dayStart != prev {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: String(describing: PreferenceHelper.getLanguage()))
                if PreferenceHelper.getLanguage() == .French {
                    dateFormatter.dateFormat = "EEEE d MMMM"
                } else {
                    dateFormatter.dateFormat = "EEEE, MMMM d"
                }
                let label = dateFormatter.string(from: hourly.date).capitalized
                result.append(.dateHeader(label, idCounter))
                idCounter += 1
            }
            currentDayStart = dayStart
            result.append(.hourly(hourly, idCounter))
            idCounter += 1
        }

        return result
    }

    var body: some View {
        List {
            ForEach(rows) { row in
                switch row {
                case .dateHeader(let label, _):
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .listRowBackground(Color.clear)
                case .hourly(let hourly, _):
                    HStack(spacing: 8) {
                        Text(hourLabel(for: hourly))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 36, alignment: .trailing)

                        Image(uiImage: hourlyImage(hourly))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)

                        Text("\(hourly.temperature)°")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()

                        if hourly.precipChance > 0 {
                            Text("\(hourly.precipChance)%")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                }
            }
        }
        .navigationTitle("Hourly".localized())
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
