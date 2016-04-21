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
        
        let path = NSBundle.mainBundle().pathForResource(PreferenceHelper.getLanguage().rawValue, ofType: "lproj")
        let bundle = NSBundle(path: path!)
        
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }

    func localized(lang: Language) ->String {
        
        let path = NSBundle.mainBundle().pathForResource(lang.rawValue, ofType: "lproj")
        let bundle = NSBundle(path: path!)
        
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}