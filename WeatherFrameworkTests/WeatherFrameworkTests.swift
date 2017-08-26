//
//  WeatherFrameworkTests.swift
//  WeatherFrameworkTests
//
//  Created by drvolks on 17-08-14.
//  Copyright © 2017 drvolks. All rights reserved.
//

import XCTest
@testable import WeatherFramework

class WeatherFrameworkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCityParser() {
        let cityParser = CityParser(outputPath: "/Users/drvolks/Downloads/")
        cityParser.perform()
    }
    
}
