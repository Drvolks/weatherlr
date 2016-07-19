//
//  StringExtension.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-18.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

extension String {
    func localized() ->String {
        
        let path = Bundle.main.pathForResource(PreferenceHelper.getLanguage().rawValue, ofType: "lproj")
        let bundle = Bundle(path: path!)
        
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }

    func localized(_ lang: Language) ->String {
        
        let path = Bundle.main.pathForResource(lang.rawValue, ofType: "lproj")
        let bundle = Bundle(path: path!)
        
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}
