//
//  AlertInformationTests.swift
//  weatherlrTests
//

import XCTest
@testable import weatherlr

class AlertInformationTests: XCTestCase {

    func testBaseInitializer() {
        let a = AlertInformation()
        XCTAssertEqual("", a.alertText)
        XCTAssertEqual("", a.alertDetails)
        XCTAssertEqual("", a.url)
        XCTAssertEqual(.none, a.type)
        XCTAssertEqual("", a.eventIssueTime)
        XCTAssertEqual("", a.expiryTime)
        XCTAssertEqual("", a.alertColourLevel)
    }

    func testShortInitializer() {
        let a = AlertInformation(alertText: "Severe weather", url: "https://example.com", type: .warning)
        XCTAssertEqual("Severe weather", a.alertText)
        XCTAssertEqual("", a.alertDetails)
        XCTAssertEqual("https://example.com", a.url)
        XCTAssertEqual(.warning, a.type)
        XCTAssertEqual("", a.eventIssueTime)
        XCTAssertEqual("", a.expiryTime)
        XCTAssertEqual("", a.alertColourLevel)
    }

    func testShortInitializerWithDetails() {
        let a = AlertInformation(alertText: "Severe weather",
                                 url: "https://example.com",
                                 type: .warning,
                                 alertDetails: "Take shelter immediately.")
        XCTAssertEqual("Severe weather", a.alertText)
        XCTAssertEqual("Take shelter immediately.", a.alertDetails)
    }

    func testFullInitializer() {
        let a = AlertInformation(alertText: "Tornado warning",
                                 url: "https://example.com",
                                 type: .warning,
                                 eventIssueTime: "2026-04-11T12:00:00Z",
                                 expiryTime: "2026-04-11T18:00:00Z",
                                 alertColourLevel: "red",
                                 alertDetails: "A tornado has been spotted. Seek shelter.")
        XCTAssertEqual("Tornado warning", a.alertText)
        XCTAssertEqual("A tornado has been spotted. Seek shelter.", a.alertDetails)
        XCTAssertEqual("https://example.com", a.url)
        XCTAssertEqual(.warning, a.type)
        XCTAssertEqual("2026-04-11T12:00:00Z", a.eventIssueTime)
        XCTAssertEqual("2026-04-11T18:00:00Z", a.expiryTime)
        XCTAssertEqual("red", a.alertColourLevel)
    }

    func testMutation() {
        let a = AlertInformation()
        a.alertText = "Updated"
        a.type = .ended
        a.alertColourLevel = "yellow"
        XCTAssertEqual("Updated", a.alertText)
        XCTAssertEqual(.ended, a.type)
        XCTAssertEqual("yellow", a.alertColourLevel)
    }
}
