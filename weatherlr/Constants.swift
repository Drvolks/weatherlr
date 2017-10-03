//
//  Constants.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class Constants {
    
    static let selectedWatchCityKey = "selectedWatchCity"
    
    
    static let requestCityMessage = "requestCityMessage"
    static let cityListKey = "cityList"
    static let searchTextKey = "searchText"
    
    static let backgroundRefreshInSeconds = 30.0 * 60.0
    #if FREE
        static let backgroundDownloadTaskName = "massawippi.weatherlr.free.download"
    #else
        static let backgroundDownloadTaskName = "massawippi.weatherlr.download"
    #endif
    
    static let googleAddId = "ca-app-pub-2793046476751764/6255610730"
    
}
