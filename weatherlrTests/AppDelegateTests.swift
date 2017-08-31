//
//  AppDelegateTests.swift
//  weatherlrTests
//
//  Created by drvolks on 17-08-31.
//  Copyright © 2017 drvolks. All rights reserved.
//

import XCTest
@testable import weatherlr

class AppDelegateTests: XCTestCase {
    var appDelegate:AppDelegate = AppDelegate()
    
    override func setUp() {
        super.setUp()
        
        appDelegate = AppDelegate()
    }
    
    func test_getCityIdFromShortcutItem() {
        var result = appDelegate.getCityIdFromShortcutItem(shortcutName: "City:123")
        XCTAssertEqual("123", result)
        
        result = appDelegate.getCityIdFromShortcutItem(shortcutName: "City:")
        XCTAssertEqual("", result)
        
        result = appDelegate.getCityIdFromShortcutItem(shortcutName: "123")
        XCTAssertEqual("", result)
        
        result = appDelegate.getCityIdFromShortcutItem(shortcutName: "Test:123")
        XCTAssertEqual("123", result)
    }
    
}
