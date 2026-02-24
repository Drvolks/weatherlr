//
//  CityPickerView.swift
//  watch Extension
//
//  Created by drvolks on 2026-02-24.
//  Copyright © 2026 drvolks. All rights reserved.
//

import SwiftUI

struct CityPickerView: View {
    let cities: [City]
    let onSelect: (City) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(header: Text("Results".localized())) {
                ForEach(sortedCities, id: \.id) { city in
                    Button {
                        onSelect(city)
                        dismiss()
                    } label: {
                        Text(CityHelper.cityName(city) + ", " + city.province.uppercased())
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel".localized()) {
                    dismiss()
                }
            }
        }
    }

    private var sortedCities: [City] {
        CityHelper.sortCityList(cities)
    }
}
