//
//  Constants.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-08.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

class Constants {
    
    static let selectedWatchCityKey = "selectedWatchCity"
    
    
    static let requestCityMessage = "requestCityMessage"
    static let cityListKey = "cityList"
    static let searchTextKey = "searchText"
    
    static let backgroundRefreshInSeconds = 30.0 * 60.0
    #if FREE
        static let backgroundDownloadTaskName = "BUNDLE_ID_PREFIX.weatherlr.free.download"
    #else
        static let backgroundDownloadTaskName = "BUNDLE_ID_PREFIX.weatherlr.download"
    #endif
    
    static let googleAddId = "ca-app-pub-2793046476751764/6255610730"
    
}
