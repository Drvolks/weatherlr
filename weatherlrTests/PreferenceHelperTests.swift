//
//  PreferenceHelpertests.swift
//  weatherlr
//
//  Created by drvolks on 2016-05-16.
//  Copyright © 2016 drvolks. All rights reserved.
//

import XCTest
@testable import weatherlr

class PreferenceHelperTests:XCTestCase {
    func testExtractLang() {
        var result = PreferenceHelper.extractLang("fr-CA")
        XCTAssertEqual("fr", result)
        
        result = PreferenceHelper.extractLang("en-CA")
        XCTAssertEqual("en", result)
        
        result = PreferenceHelper.extractLang("en")
        XCTAssertEqual("en", result)
    }
}