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
        let bundle = NSBundle(forClass: self.dynamicType)
        if let path = bundle.pathForResource(xmlName, ofType: "xml")
        {
            let xmlData = NSData(contentsOfFile: path)!
            super.init(xmlData: xmlData, language: language)
        } else {
            return nil
        }
    }
}
