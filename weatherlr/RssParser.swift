//
//  RssParser.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class RssParser : RssParserBase {
    var parser:NSXMLParser
    var rssEntries = [RssEntry]()
    var language:Language
    
    let entryElement = "entry"
    
    init(xmlData: NSData, language: Language) {
        parser = NSXMLParser(data: xmlData)
        self.language = language
    }
    
    init?(url: NSURL, language: Language) {
        if let tryParser = NSXMLParser(contentsOfURL: url) {
            parser = tryParser
        } else {
            return nil
        }
        
        self.language = language
    }
    
    func parse() -> [RssEntry] {
        parser.delegate = self
        parser.parse()
        
        return rssEntries
    }
    
    @objc override func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        super.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
        switch elementName {
        case entryElement:
            let rssEntry = RssEntry(parent: self, language: language)
            parser.delegate = rssEntry
            rssEntries.append(rssEntry)
        default: break
        }
    }
    
    @objc func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
    }
    
    

}
