//
//  RssParserBase.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-05.
//  Copyright © 2016 drvolks. All rights reserved.
//

import UIKit

class RssParserBase : NSObject, NSXMLParserDelegate {
    var currentElement = ""
    var foundCharacters = "";
    var currentAttributes:[String:String] = [:]
    
    @objc func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        self.currentElement = elementName
        self.currentAttributes = attributeDict
    }
    
    @objc func parser(parser: NSXMLParser, foundCharacters string: String) {
        self.foundCharacters += string
    }
}
