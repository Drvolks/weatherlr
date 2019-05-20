//
//  AppDelegate.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit
#if FREE
    import Firebase
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var shortcutItem: UIApplicationShortcutItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        PreferenceHelper.upgrade()
        
        #if FREE
            FirebaseApp.configure()
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif
        
        var performShortcutDelegate = true
        
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            self.shortcutItem = shortcutItem
            
            performShortcutDelegate = false
        }
        
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        UINavigationBar.appearance().barTintColor = UIColor(weatherColor: WeatherColor.defaultColor)
        UIToolbar.appearance().tintColor = UIColor.white
        UIToolbar.appearance().barTintColor = UIColor(weatherColor: WeatherColor.defaultColor)
        
        return performShortcutDelegate
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Swift.Void) {
        completionHandler(handleQuickAction(application: application, shortcutItem: shortcutItem))
    }
    
    @discardableResult
    func handleQuickAction(application: UIApplication, shortcutItem: UIApplicationShortcutItem) -> Bool {
        print("Handling shortcut")
        
        let cityId = getCityIdFromShortcutItem(shortcutName: shortcutItem.type)
        
        PreferenceHelper.switchFavoriteCity(cityId: cityId)
        
        let mainSB = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainSB.instantiateViewController(withIdentifier: "WeatherView") as! WeatherViewController
        
        let navVC = self.window?.rootViewController as! UINavigationController
        navVC.pushViewController(viewController, animated: true)
        
        return true
    }

    func getCityIdFromShortcutItem(shortcutName:String) -> String {
        if let index = shortcutName.range(of: ":") {
            return String(shortcutName[index.upperBound..<shortcutName.endIndex])
        }
        
        return ""
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard let shortcut = shortcutItem else { return }
        
        handleQuickAction(application: application, shortcutItem: shortcut)
        
        self.shortcutItem = nil
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

