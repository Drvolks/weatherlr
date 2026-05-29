//
//  UrlHelper.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-08.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

public class UrlHelper {
    public static func getUrl(_ city: City) -> String {
        return "https://api.weather.gc.ca/collections/citypageweather-realtime/items/\(city.id)?f=json"
    }

    public static func getUrl(_ city: City, lang: Language) -> String {
        let langParam = lang == .French ? "fr-CA" : "en-CA"
        return "https://api.weather.gc.ca/collections/citypageweather-realtime/items/\(city.id)?f=json&lang=\(langParam)"
    }

    /// The reference anchor at the end of a citypageweather warning URL
    /// (e.g. `...report_e.html?qcrm12#15100181610...`). This matches the leading
    /// part of a `weather-alerts` feature id and is the key used to fetch the
    /// full bulletin text. Returns nil when the URL carries no anchor.
    public static func getAlertAnchor(fromWarningUrl url: String) -> String? {
        guard let hashIndex = url.firstIndex(of: "#") else { return nil }
        let anchor = String(url[url.index(after: hashIndex)...])
        return anchor.isEmpty ? nil : anchor
    }

    /// weather-alerts query that returns the full bulletin for the given anchor.
    /// `id LIKE '<anchor>%'` matches every per-region feature of the alert; they
    /// share the same text, so the caller only needs the first.
    public static func getAlertDetailUrl(anchor: String) -> String? {
        let filter = "id LIKE '\(anchor)%'"
        guard let encoded = filter.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return nil
        }
        return "https://api.weather.gc.ca/collections/weather-alerts/items?f=json&limit=1&filter=\(encoded)"
    }
}
