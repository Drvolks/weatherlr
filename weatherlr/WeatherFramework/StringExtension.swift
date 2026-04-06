//
//  StringExtension.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-18.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

nonisolated(unsafe) private var bundleCache = [String: Bundle]()

private let commaFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.decimalSeparator = ","
    return f
}()

private let dotFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.decimalSeparator = "."
    return f
}()

public extension String {
    func localized() -> String {
        return localized(PreferenceHelper.getLanguage())
    }

    func localized(_ lang: Language) -> String {
        let key = lang.rawValue
        if let bundle = bundleCache[key] {
            return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
        }

        guard let path = Bundle.main.path(forResource: key, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return self
        }

        bundleCache[key] = bundle
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
    }

    var isDouble: Bool {
        return commaFormatter.number(from: self) != nil || dotFormatter.number(from: self) != nil
    }
}
