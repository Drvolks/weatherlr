//
//  RssParserBase.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-05.
//  Copyright © 2016 drvolks. All rights reserved.
//

import UIKit

class RssParserBase : NSObject, XMLParserDelegate {
    var currentElement = ""
    var foundCharacters = "";
    var currentAttributes:[String:String] = [:]
    
    @objc func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        self.currentElement = elementName
        self.currentAttributes = attributeDict
    }
    
    @objc func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.foundCharacters += string
    }
}
