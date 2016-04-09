//
//  RssEntryTests.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-05.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import XCTest
@testable import weatherlr

class RssEntryTests: XCTestCase {
    func testRssEntryConstructor() {
        let rssParser = RssParserStub(xmlName: "TestDataEntry")!
            
        let result = RssEntry(parent: rssParser)
        XCTAssertNotNil(result)
    }
    
    func testParseEntry() {
        // forcast
        var rssParser = RssParserStub(xmlName: "TestDataEntry")!
        var entry = RssEntry(parent: rssParser)
        rssParser.parser.delegate = entry
        rssParser.parser.parse()
            
        XCTAssertEqual("Ce soir et cette nuit: Quelques nuages. Minimum moins 12.", entry.title)
        XCTAssertEqual("Prévisions météo", entry.category)
        XCTAssertEqual("Quelques nuages. Minimum moins 12. Prévisions émises 15h45 HAE lundi 04 avril 2016", entry.summary)
        XCTAssertEqual("2016-04-04T19:45:00Z", entry.updated)
        
        rssParser = RssParserStub(xmlName: "TestDataEntry_EN")!
        entry = RssEntry(parent: rssParser)
        rssParser.parser.delegate = entry
        rssParser.parser.parse()
        
        XCTAssertEqual("Tuesday: Sunny. High minus 2.", entry.title)
        XCTAssertEqual("Weather Forecasts", entry.category)
        XCTAssertEqual("Sunny. Wind north 20 km/h becoming west 20 near noon. High minus 2. UV index 4 or moderate. Forecast issued 05:00 AM EDT Tuesday 05 April 2016", entry.summary)
        XCTAssertEqual("2016-04-05T09:00:00Z", entry.updated)
        
        // current weather
        rssParser = RssParserStub(xmlName: "TestDataEntryCurrent")!
        entry = RssEntry(parent: rssParser)
        rssParser.parser.delegate = entry
        rssParser.parser.parse()

        var summary = "<b>Enregistrées à:</b> Aéroport int. de Montréal-Trudeau 17h00 HAE lundi 04 avril 2016 <br/>\n        <b>Condition:</b> Partiellement nuageux <br/>\n        <b>Température:</b> -3,5&deg;C <br/>\n        <b>Pression / Tendance:</b> 101,9 kPa à la baisse<br/>\n        <b>Visibilité:</b> 48,3 km<br/>\n        <b>Humidité:</b> 30 %<br/>\n        <b>Refroidissement éolien:</b> -5 <br/>\n        <b>Point de rosée:</b> -18,8&deg;C <br/>\n        <b>Vent:</b> NE 4 km/h<br/>\n        <b>Cote air santé:</b>  <br/>"
        XCTAssertEqual(summary, entry.summary)
        XCTAssertEqual("Conditions actuelles: Partiellement nuageux, -3,5°C", entry.title)
        XCTAssertEqual("Conditions actuelles", entry.category)
        XCTAssertEqual("2016-04-04T21:00:00Z", entry.updated)
        
        rssParser = RssParserStub(xmlName: "TestDataEntryCurrent_EN")!
        entry = RssEntry(parent: rssParser)
        rssParser.parser.delegate = entry
        rssParser.parser.parse()
        
        summary = "<b>Observed at:</b> Montréal-Trudeau Int\'l Airport 08:00 AM EDT Tuesday 05 April 2016 <br/>\n        <b>Condition:</b> Mainly Sunny <br/>\n        <b>Temperature:</b> -8.2&deg;C <br/>\n        <b>Pressure / Tendency:</b> 103.0 kPa rising<br/>\n        <b>Visibility:</b> 24.1 km<br/>\n        <b>Humidity:</b> 48 %<br/>\n        <b>Wind Chill:</b> -14 <br/>\n        <b>Dewpoint:</b> -17.4&deg;C <br/>\n        <b>Wind:</b> NNE 14 km/h<br/>\n        <b>Air Quality Health Index:</b>  <br/>"
        XCTAssertEqual(summary, entry.summary)
        XCTAssertEqual("Current Conditions: Mainly Sunny, -8.2°C", entry.title)
        XCTAssertEqual("Current Conditions", entry.category)
        XCTAssertEqual("2016-04-05T12:00:00Z", entry.updated)
    }
}
