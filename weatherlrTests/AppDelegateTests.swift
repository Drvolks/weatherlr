//
//  AppDelegateTests.swift
//  weatherlrTests
//
//  Created by drvolks on 17-08-31.
//  Copyright © 2017 drvolks. All rights reserved.
//

import XCTest
@testable import weatherlr

@MainActor
class AppDelegateTests: XCTestCase {
    var sceneDelegate = SceneDelegate()
    
    override func setUp() {
        super.setUp()
        
        sceneDelegate = SceneDelegate()
    }
    
    func test_getCityIdFromShortcutItem() {
        var result = sceneDelegate.getCityIdFromShortcutItem(shortcutName: "City:123")
        XCTAssertEqual("123", result)
        
        result = sceneDelegate.getCityIdFromShortcutItem(shortcutName: "City:")
        XCTAssertEqual("", result)
        
        result = sceneDelegate.getCityIdFromShortcutItem(shortcutName: "123")
        XCTAssertEqual("", result)
        
        result = sceneDelegate.getCityIdFromShortcutItem(shortcutName: "Test:123")
        XCTAssertEqual("123", result)
    }
    
}
