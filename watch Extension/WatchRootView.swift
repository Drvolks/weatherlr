//
//  WatchRootView.swift
//  watch Extension
//
//  Created by drvolks on 2026-07-18.
//  Copyright © 2026 drvolks. All rights reserved.
//

import SwiftUI

/// Root of the watch app: horizontal paging between the forecast (page 0)
/// and the radar (page 1). The forecast page keeps its own NavigationStack
/// and behavior unchanged.
struct WatchRootView: View {
    @State private var model = WatchWeatherModel.shared

    var body: some View {
        TabView {
            WeatherContentView()
            WatchRadarView()
        }
        .environment(model)
    }
}
