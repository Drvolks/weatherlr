//
//  AlertFinder.swift
//  weatherlr
//
//  Created by drvolks on 2016-05-16.
//  Copyright © 2016 drvolks. All rights reserved.
//

import XCTest
@testable import weatherlr

class AlertTests: XCTestCase {
    let testBundle = Bundle(for: AlertTests.self)
    /*
    func testFindAlerts1() {
        findAlert("/cities")
    }
    */
    // MARK: - Alert body (#20)

    func testConvertAlertPopulatesDetailsFromRssSummary() {
        let file = testBundle.path(forResource: "cities1/qc-128_English", ofType: "xml")!
        let xmlData = try! Data(contentsOf: URL(fileURLWithPath: file))
        let rssEntries = RssParser(xmlData: xmlData, language: .English).parse()

        let alerts = RssEntryToWeatherInformation(rssEntries: rssEntries).getAlerts()

        XCTAssertFalse(alerts.isEmpty, "Fixture qc-128 should contain a BLIZZARD WARNING")
        let blizzard = alerts.first { $0.alertText.uppercased().contains("BLIZZARD") }
        XCTAssertNotNil(blizzard)
        // The RSS summary carries a body the JSON API does not — it must survive.
        XCTAssertFalse(blizzard!.alertDetails.isEmpty)
        XCTAssertTrue(blizzard!.alertDetails.contains("adverse weather conditions"))
        // No leftover HTML markup.
        XCTAssertFalse(blizzard!.alertDetails.contains("<"))
    }

    func testStripHtmlRemovesTagsAndDecodesEntities() {
        let converter = RssEntryToWeatherInformation(rssEntries: [])
        XCTAssertEqual("Plain text", converter.stripHtml("Plain text"))
        XCTAssertEqual("Line one Line two",
                       converter.stripHtml("<b>Line one</b><br/>Line two"))
        XCTAssertEqual("-4°C & windy", converter.stripHtml("-4&deg;C &amp; windy"))
        XCTAssertEqual("", converter.stripHtml("   "))
    }

    func findAlert(_ subPath: String) {
        let fileManager = FileManager.default
        let path = testBundle.resourcePath!
        let items = try! fileManager.contentsOfDirectory(atPath: path + subPath)
        
        for item in items {
            let url = URL(fileURLWithPath: item)
            let baseName = url.deletingPathExtension().lastPathComponent
            
            if let file = testBundle.path(forResource: subPath + "/" + baseName, ofType: "xml")
            {
                var lang = Language.French
                if file.contains(String(describing: Language.English)) {
                    lang = Language.English
                }
                
                let xmlData = try! Data(contentsOf: URL(fileURLWithPath: file))
                let parser = RssParser(xmlData: xmlData, language: lang)
                
                let rssEntries = parser.parse()
                
                var alerts = 0
                for rssEntry in rssEntries {
                    let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
                    
                    if performer.isAlert(rssEntry.title) {
                        alerts = alerts + 1
                    }
                }
            }
        }
    }
}
