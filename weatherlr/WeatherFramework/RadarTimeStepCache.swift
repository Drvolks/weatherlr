//
//  RadarTimeStepCache.swift
//  weatherlr
//
//  Created by drvolks on 2024-01-01.
//  Copyright © 2024 drvolks. All rights reserved.
//

import Foundation

class RadarTimeStepCache: @unchecked Sendable {
    static let shared = RadarTimeStepCache()

    private let lock = NSLock()
    private var cachedSteps: [String] = []
    private var fetchDate: Date?
    private var isFetching = false

    private init() {}

    func preload() {
        lock.lock()
        let shouldFetch: Bool
        if isFetching {
            print("[RadarCache] preload skipped — already fetching")
            shouldFetch = false
        } else if let fetchDate = fetchDate, Date().timeIntervalSince(fetchDate) < 300 {
            print("[RadarCache] preload skipped — cache is \(Int(Date().timeIntervalSince(fetchDate)))s old (< 300s)")
            shouldFetch = false
        } else {
            print("[RadarCache] preload starting fetch...")
            shouldFetch = true
            isFetching = true
        }
        lock.unlock()

        guard shouldFetch else { return }

        let startTime = Date()
        let urlString = "https://geo.weather.gc.ca/geomet?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities&LAYERS=RADAR_1KM_RRAI"
        guard let url = URL(string: urlString) else {
            print("[RadarCache] preload failed — invalid URL")
            lock.lock()
            isFetching = false
            lock.unlock()
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            let elapsed = Date().timeIntervalSince(startTime)
            guard let self = self else {
                print("[RadarCache] preload failed — self deallocated after \(String(format: "%.1f", elapsed))s")
                return
            }
            guard let data = data, error == nil else {
                print("[RadarCache] preload failed — \(error?.localizedDescription ?? "no data") after \(String(format: "%.1f", elapsed))s")
                self.lock.lock()
                self.isFetching = false
                self.lock.unlock()
                return
            }

            let parser = TimeDimensionParser(data: data)
            let steps = parser.parse()

            self.lock.lock()
            if !steps.isEmpty {
                self.cachedSteps = steps
                self.fetchDate = Date()
                print("[RadarCache] preload complete — \(steps.count) steps cached in \(String(format: "%.1f", elapsed))s")
            } else {
                print("[RadarCache] preload failed — parsed 0 steps from \(data.count) bytes in \(String(format: "%.1f", elapsed))s")
            }
            self.isFetching = false
            self.lock.unlock()
        }.resume()
    }

    func getCachedSteps() -> [String]? {
        lock.lock()
        defer { lock.unlock() }
        guard !cachedSteps.isEmpty,
              let fetchDate = fetchDate,
              Date().timeIntervalSince(fetchDate) < 1800 else {
            print("[RadarCache] getCachedSteps — cache miss (empty=\(cachedSteps.isEmpty), age=\(fetchDate.map { "\(Int(Date().timeIntervalSince($0)))s" } ?? "nil"))")
            return nil
        }
        print("[RadarCache] getCachedSteps — cache hit, \(cachedSteps.count) steps, age=\(Int(Date().timeIntervalSince(fetchDate)))s")
        return cachedSteps
    }
}

// MARK: - TimeDimensionParser

class TimeDimensionParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var foundDimension = false
    private var dimensionValue = ""
    private var timeSteps: [String] = []

    init(data: Data) {
        self.data = data
    }

    func parse() -> [String] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return timeSteps
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "Dimension" && attributeDict["name"] == "time" {
            foundDimension = true
            dimensionValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if foundDimension {
            dimensionValue += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "Dimension" && foundDimension {
            foundDimension = false
            let trimmed = dimensionValue.trimmingCharacters(in: .whitespacesAndNewlines)
            timeSteps = generateTimeSteps(from: trimmed)
            parser.abortParsing()
        }
    }

    private func generateTimeSteps(from dimension: String) -> [String] {
        let parts = dimension.split(separator: "/")
        guard parts.count == 3 else { return [] }

        let startStr = String(parts[0])
        let endStr = String(parts[1])
        let intervalStr = String(parts[2])

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        guard let startDate = formatter.date(from: startStr),
              let endDate = formatter.date(from: endStr),
              let intervalSeconds = parseISO8601Duration(intervalStr) else {
            return []
        }

        var steps: [String] = []
        var current = startDate
        while current <= endDate {
            steps.append(formatter.string(from: current))
            current = current.addingTimeInterval(intervalSeconds)
        }
        return steps
    }

    private func parseISO8601Duration(_ duration: String) -> TimeInterval? {
        var str = duration
        guard str.hasPrefix("PT") else { return nil }
        str.removeFirst(2)

        var totalSeconds: TimeInterval = 0
        var numberStr = ""

        for char in str {
            if char.isNumber {
                numberStr.append(char)
            } else {
                guard let value = Double(numberStr) else { return nil }
                switch char {
                case "H": totalSeconds += value * 3600
                case "M": totalSeconds += value * 60
                case "S": totalSeconds += value
                default: return nil
                }
                numberStr = ""
            }
        }

        return totalSeconds > 0 ? totalSeconds : nil
    }
}
