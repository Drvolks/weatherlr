//
//  RssParser.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-04.
//  Copyright © 2016 drvolks. All rights reserved.
//

import UIKit

class RssParser : RssParserBase {
    var parser:XMLParser
    var rssEntries = [RssEntry]()
    var language:Language
    
    let entryElement = "entry"
    
    init(xmlData: Data, language: Language) {
        parser = XMLParser(data: xmlData)
        self.language = language
    }
    
    init?(url: URL, language: Language) {
        if let tryParser = XMLParser(contentsOf: url) {
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
    
    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        super.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
        switch elementName {
        case entryElement:
            let rssEntry = RssEntry(parent: self, language: language)
            parser.delegate = rssEntry
            rssEntries.append(rssEntry)
        default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
    }
    
    

}
