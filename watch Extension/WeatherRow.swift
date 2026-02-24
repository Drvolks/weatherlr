//
//  WeatherRow.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2026-02-24.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import SwiftUI

struct WeatherRow: View {
    let weather: WeatherInformation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(WeatherHelper.getWeatherDayWhenText(weather))
                .font(.subheadline)

            HStack {
                Image(uiImage: weather.image())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 25)

                Spacer()

                Image(uiImage: WeatherHelper.textToImageMinMax(weather))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(5)
        .background(Color.white.opacity(0.15))
        .cornerRadius(8)
    }
}
