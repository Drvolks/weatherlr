//
//  AlertFinder.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-16.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
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
    func findAlert(_ subPath: String) {
        let fileManager = FileManager.default
        let path = testBundle.resourcePath!
        let items = try! fileManager.contentsOfDirectory(atPath: path + subPath)
        
        for item in items {
            let url = URL(fileURLWithPath: item)
            let baseName = try! url.deletingPathExtension().lastPathComponent!
            
            if let file = testBundle.pathForResource(subPath + "/" + baseName, ofType: "xml")
            {
                var lang = Language.French
                if file.contains(String(Language.English)) {
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
                
                if alerts > 1 {
                    print(baseName)
                }
            }
        }
    }
}
