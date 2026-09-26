//
//  AppDelegate.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-04.
//  Copyright © 2016 drvolks. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // When launched under UI tests with `-UITest`, seed defaults and cache
        // so the main screen renders without network or location.
        UITestSupport.seedIfNeeded()

        PreferenceHelper.upgrade()
        WatchSyncManager.shared.activate()

        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        UINavigationBar.appearance().barTintColor = UIColor(weatherColor: WeatherColor.defaultColor)
        UIToolbar.appearance().tintColor = UIColor.white
        UIToolbar.appearance().barTintColor = UIColor(weatherColor: WeatherColor.defaultColor)

        // The window and Home Screen quick actions are handled by SceneDelegate.
        return true
    }
}
