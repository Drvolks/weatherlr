//
//  SceneDelegate.swift
//  weatherlr
//
//  Created by drvolks on 2026-09-26.
//  Copyright © 2026 drvolks. All rights reserved.
//

import UIKit

// UIKit asserts at launch on iOS 27 for apps built with the iOS 27 SDK that don't
// adopt the scene life cycle. The window comes from the storyboard declared in the
// scene manifest (Info.plist); this delegate only owns it and routes Home Screen
// quick actions, which UIKit now delivers to the scene instead of the app delegate.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var shortcutItem: UIApplicationShortcutItem?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Handled once the scene is active, so the storyboard's navigation controller exists.
        shortcutItem = connectionOptions.shortcutItem
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleQuickAction(shortcutItem: shortcutItem))
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let shortcut = shortcutItem else { return }

        handleQuickAction(shortcutItem: shortcut)

        shortcutItem = nil
    }

    @discardableResult
    func handleQuickAction(shortcutItem: UIApplicationShortcutItem) -> Bool {
        print("Handling shortcut")

        let cityId = getCityIdFromShortcutItem(shortcutName: shortcutItem.type)

        PreferenceHelper.switchFavoriteCity(cityId: cityId)

        let mainSB = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = mainSB.instantiateViewController(withIdentifier: "WeatherView") as? WeatherViewController,
              let navVC = window?.rootViewController as? UINavigationController else {
            return false
        }
        navVC.pushViewController(viewController, animated: true)

        return true
    }

    func getCityIdFromShortcutItem(shortcutName: String) -> String {
        if let index = shortcutName.range(of: ":") {
            return String(shortcutName[index.upperBound..<shortcutName.endIndex])
        }

        return ""
    }
}
