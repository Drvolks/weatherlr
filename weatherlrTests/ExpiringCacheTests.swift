//
//  ExpiringCacheTests.swift
//  weatherlrTests
//

import XCTest
@testable import weatherlr

class ExpiringCacheTests: XCTestCase {

    func testMissingKeyReturnsNil() {
        let cache = ExpiringCache<String>()
        XCTAssertNil(cache.object(forKey: "nope"))
    }

    func testSetAndGet() {
        let cache = ExpiringCache<String>()
        cache.setObject("value", forKey: "key")
        XCTAssertEqual("value", cache.object(forKey: "key"))
    }

    func testOverwriteReplacesValue() {
        let cache = ExpiringCache<Int>()
        cache.setObject(1, forKey: "key")
        cache.setObject(2, forKey: "key")
        XCTAssertEqual(2, cache.object(forKey: "key"))
    }

    func testKeysAreIsolated() {
        let cache = ExpiringCache<String>()
        cache.setObject("a", forKey: "k1")
        cache.setObject("b", forKey: "k2")
        XCTAssertEqual("a", cache.object(forKey: "k1"))
        XCTAssertEqual("b", cache.object(forKey: "k2"))
    }

    func testExpiredValueIsRemovedAndNil() {
        let cache = ExpiringCache<String>()
        // Negative timeout → entry is already expired on read
        cache.setObject("stale", forKey: "k", timeout: -1)
        XCTAssertNil(cache.object(forKey: "k"))
        // Second read still nil (entry purged)
        XCTAssertNil(cache.object(forKey: "k"))
    }

    func testNotYetExpiredIsStillAvailable() {
        let cache = ExpiringCache<String>()
        cache.setObject("fresh", forKey: "k", timeout: 60)
        XCTAssertEqual("fresh", cache.object(forKey: "k"))
    }

    func testRemoveObject() {
        let cache = ExpiringCache<String>()
        cache.setObject("v", forKey: "k", timeout: 60)
        cache.removeObject(forKey: "k")
        XCTAssertNil(cache.object(forKey: "k"))
    }

    func testRemoveAllObjects() {
        let cache = ExpiringCache<String>()
        cache.setObject("v1", forKey: "k1", timeout: 60)
        cache.setObject("v2", forKey: "k2", timeout: 60)
        cache.removeAllObjects()
        XCTAssertNil(cache.object(forKey: "k1"))
        XCTAssertNil(cache.object(forKey: "k2"))
    }

    func testDefaultTimeoutKeepsEntryAvailable() {
        // Default timeout is 30 minutes — the value should be readable immediately.
        let cache = ExpiringCache<String>()
        cache.setObject("v", forKey: "k")
        XCTAssertEqual("v", cache.object(forKey: "k"))
    }

    func testRemoveMissingKeyIsNoop() {
        let cache = ExpiringCache<String>()
        cache.removeObject(forKey: "does-not-exist")
        XCTAssertNil(cache.object(forKey: "does-not-exist"))
    }
}
