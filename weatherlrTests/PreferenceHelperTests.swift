//
//  PreferenceHelpertests.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-16.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
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