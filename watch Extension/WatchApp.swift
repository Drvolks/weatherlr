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
                .onOpenURL { url in
                    // Tapping the complication launches the app via the
                    // "previca://open" URL. No parameters are parsed yet;
                    // this handler is the hook for future deep-linking.
                    _ = url
                }
        }
    }
}
