//
//  StringExtension.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-18.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

public extension String {
    func localized() ->String {
        
        let path = Bundle.main.path(forResource: PreferenceHelper.getLanguage().rawValue, ofType: "lproj")
        let bundle = Bundle(path: path!)
        
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }

    func localized(_ lang: Language) ->String {
        
        let path = Bundle.main.path(forResource: lang.rawValue, ofType: "lproj")
        let bundle = Bundle(path: path!)
        
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }

    var isDouble: Bool {
        if(isDouble(",")) {
            return true
        }
        
        return isDouble(".")
    }
    
    private func isDouble(_ delemiter:String) -> Bool {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = delemiter
        let doubleFormatted = formatter.number(from: self)

        if (doubleFormatted?.doubleValue) != nil {
            return true
        }
        
        return false
    }
}
