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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        print("Application did finish launching with options")
        
        #if FREE
            FIRApp.configure()
            GADMobileAds.configure(withApplicationID: Constants.googleAddId);
        #endif
        
        var performShortcutDelegate = true
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            self.shortcutItem = shortcutItem
            
            performShortcutDelegate = false
        }
        
        return performShortcutDelegate
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Swift.Void) {
        print("Application performActionForShortcutItem")
        
        completionHandler(handleQuickAction(application: application, shortcutItem: shortcutItem))
    }
    
    func handleQuickAction(application: UIApplication, shortcutItem: UIApplicationShortcutItem) -> Bool {
        print("Handling shortcut")
        
        let index = shortcutItem.type.range(of: ":")?.upperBound
        let cityId = shortcutItem.type.substring(from: index!)
        
        PreferenceHelper.switchFavoriteCity(cityId: cityId)
        
        let mainSB = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainSB.instantiateViewController(withIdentifier: "WeatherView") as! WeatherViewController
        
        let navVC = self.window?.rootViewController as! UINavigationController
        navVC.pushViewController(viewController, animated: true)
        
        return true
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
        print("Application did become active")
        
        guard let shortcut = shortcutItem else { return }
        
        print("- Shortcut property has been set")
        
        handleQuickAction(application: application, shortcutItem: shortcut)
        
        self.shortcutItem = nil
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

