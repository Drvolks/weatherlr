//
//  RssParserStub.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-05.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit
@testable import weatherlr

class RssParserStub : RssParser {
    convenience init?() {
        self.init(xmlName: "TestData", language: Language.French)
    }
    
    convenience init?(xmlName: String) {
        self.init(xmlName: xmlName, language: Language.French)
    }
    
    init?(xmlName: String, language: Language) {
        let bundle = Bundle(for: type(of: self))
        if let path = bundle.path(forResource: xmlName, ofType: "xml")
        {
            let xmlData = try! Data(contentsOf: URL(fileURLWithPath: path))
            super.init(xmlData: xmlData, language: language)
        } else {
            return nil
        }
    }
}
