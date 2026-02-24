//
//  WatchApp.swift
//  watch Extension
//
//  Created by drvolks on 2026-02-24.
//  Copyright © 2026 drvolks. All rights reserved.
//

import SwiftUI

@main
struct WatchApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            WeatherContentView()
        }
    }
}
