//
//  StringExtension.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-18.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

extension String {
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
}
