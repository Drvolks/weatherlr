//
//  NextWeatherRow.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2026-02-24.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import SwiftUI

struct NextWeatherRow: View {
    let weather: WeatherInformation
    let previousWeatherPresent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(WeatherHelper.getWeatherDayWhenText(weather))
                .font(.subheadline)

            HStack {
                Image(uiImage: weather.image())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 25)

                Text(detailLine1)
                    .font(.footnote)
                    .lineLimit(nil)

                Spacer()

                if !previousWeatherPresent {
                    Image(uiImage: WeatherHelper.textToImageMinMax(weather))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
            }

            if !detailLine2.isEmpty {
                Text(detailLine2)
                    .font(.footnote)
                    .lineLimit(nil)
            }
        }
        .padding(5)
        .background(Color.white.opacity(0.15))
        .cornerRadius(8)
    }

    private var detailLine1: String {
        if let range = weather.detail.range(of: ".") {
            return String(weather.detail.prefix(upTo: range.lowerBound)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return weather.detail
    }

    private var detailLine2: String {
        if let range = weather.detail.range(of: ".") {
            return String(weather.detail.suffix(from: range.upperBound)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
}
