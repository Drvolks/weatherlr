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
    let testBundle = NSBundle(forClass: AlertTests.self)
    
    func testFindAlerts1() {
        findAlert("/cities")
    }
    
    func findAlert(subPath: String) {
        let fileManager = NSFileManager.defaultManager()
        let path = testBundle.resourcePath!
        let items = try! fileManager.contentsOfDirectoryAtPath(path + subPath)
        
        for item in items {
            let url = NSURL(fileURLWithPath: item)
            let baseName = url.URLByDeletingPathExtension?.lastPathComponent!
            
            if let file = testBundle.pathForResource(subPath + "/" + baseName!, ofType: "xml")
            {
                var lang = Language.French
                if file.containsString(String(Language.English)) {
                    lang = Language.English
                }
                
                let xmlData = NSData(contentsOfFile: file)!
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