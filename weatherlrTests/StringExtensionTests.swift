//
//  StringExtensionTests.swift
//  weatherlrTests
//

import XCTest
@testable import weatherlr

class StringExtensionTests: XCTestCase {

    func testIsDoubleAcceptsDotSeparator() {
        XCTAssertTrue("12.5".isDouble)
        XCTAssertTrue("-3.14".isDouble)
        XCTAssertTrue("0".isDouble)
        XCTAssertTrue("1000".isDouble)
    }

    func testIsDoubleAcceptsCommaSeparator() {
        XCTAssertTrue("12,5".isDouble)
        XCTAssertTrue("-3,14".isDouble)
    }

    func testIsDoubleRejectsNonNumeric() {
        XCTAssertFalse("abc".isDouble)
        XCTAssertFalse("".isDouble)
        XCTAssertFalse("12.34.56".isDouble)
    }

    func testLocalizedReturnsNonEmpty() {
        // "Today" has a known localization in Localizable.strings
        let result = "Today".localized(.English)
        XCTAssertFalse(result.isEmpty)
    }

    func testLocalizedFrench() {
        let english = "Today".localized(.English)
        let french = "Today".localized(.French)
        // Both should resolve to something non-empty. They may differ if the
        // localization table is populated in both languages.
        XCTAssertFalse(english.isEmpty)
        XCTAssertFalse(french.isEmpty)
    }

    func testLocalizedUnknownKeyFallsBackToKey() {
        let unknown = "ZZZ_UNKNOWN_KEY_THAT_DOES_NOT_EXIST".localized(.English)
        // NSLocalizedString returns the key when no translation is found
        XCTAssertEqual("ZZZ_UNKNOWN_KEY_THAT_DOES_NOT_EXIST", unknown)
    }
}
