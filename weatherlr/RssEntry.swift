//
//  RssEntry.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-05.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class RssEntry : RssParserBase {
    var title = ""
    var updated = ""
    var summary = ""
    var category = ""
    var day = 0
    var language:Language
    var parent:RssParser
    var link:String = ""
    
    let titleElement = "title"
    let categoryElement = "category"
    let summaryElement = "summary"
    let updatedElement = "updated"
    let entryElement = "entry"
    let linkElement = "link"
    
    init(parent: RssParser, language: Language) {
        self.parent = parent
        self.language = language
    }
    
    init(parent: RssParser) {
        self.parent = parent
        self.language = Language.French
    }
    
    @objc func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case titleElement:
            self.title = foundCharacters.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            break
        case categoryElement:
            if let term = currentAttributes["term"] {
                self.category = term
            }
            break
        case updatedElement:
            self.updated = foundCharacters.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            break
        case summaryElement:
            self.summary = foundCharacters.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            break
        case linkElement:
            self.link = foundCharacters.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            break
        case entryElement:
            parent.parser.delegate = parent
            break
        default: break
        }
        
        foundCharacters = ""
    }
}
