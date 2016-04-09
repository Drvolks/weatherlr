//
//  RssParserTests.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import XCTest
@testable import weatherlr

class RssParserTests: XCTestCase {
    func testRssParserConstructor() {
        let bundle = NSBundle(forClass: self.dynamicType)
        if let path = bundle.pathForResource("TestData", ofType: "xml")
        {
            let xmlData = NSData(contentsOfFile: path)!
        
            let result = RssParser(xmlData: xmlData, language: Language.French)
            XCTAssertNotNil(result)
        } else {
            XCTFail("Erreur bundle.pathForResource")
        }
    }
    
    func testRssParserConstructorWithUrl() {
        if let url = NSURL(string: "https://meteo.gc.ca/rss/city/qc-147_f.xml") {
            let result = RssParser(url: url, language: Language.French)
            XCTAssertNotNil(result)
        } else {
            XCTFail("Erreur NSURL")
        }
    }
    
    func testParse() {
        let bundle = NSBundle(forClass: self.dynamicType)
        if let path = bundle.pathForResource("TestData", ofType: "xml")
        {
            let xmlData = NSData(contentsOfFile: path)!
            
            let parser = RssParser(xmlData: xmlData, language: Language.French)
            let result = parser.parse()
            XCTAssertNotNil(result)
            XCTAssertEqual(14, result.count)
            
            for i in 0..<result.count {
                XCTAssertNotNil(result[i].title)
                XCTAssertFalse(result[i].title.isEmpty)
            }
        }
        else {
            XCTFail("Erreur bundle.pathForResource")
        }
    }
    
    func testParseFromUrl() {
        if let url = NSURL(string: "https://meteo.gc.ca/rss/city/qc-147_f.xml") {
            if let parser = RssParser(url: url, language: Language.French) {
                let result = parser.parse()
                XCTAssertNotNil(result)
                XCTAssertTrue(result.count > 7)
                
                for i in 0..<result.count {
                    XCTAssertNotNil(result[i].title)
                    XCTAssertFalse(result[i].title.isEmpty)
                }
            } else {
                XCTFail("Erreur RssParser")
            }
        }
        else {
            XCTFail("Erreur NSURL")
        }
    }
    
    func testParsePerformance() {
        self.measureBlock {
            let bundle = NSBundle(forClass: self.dynamicType)
            if let path = bundle.pathForResource("TestData", ofType: "xml")
            {
                let xmlData = NSData(contentsOfFile: path)!
                
                let parser = RssParser(xmlData: xmlData, language: Language.French)
                let result = parser.parse()
                XCTAssertEqual(14, result.count)
            } else {
                XCTFail("Erreur bundle.pathForResource")
            }
        }
    }
}
