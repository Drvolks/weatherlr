//
//  SelectCityController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-09.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit

class SelectCityController: WKInterfaceController {
    @IBOutlet var cityTable: WKInterfaceTable!
    @IBOutlet var cancelButton: WKInterfaceButton!
    @IBOutlet var searchLabel: WKInterfaceLabel!
    
    var cities = [City]()
    var delegate:WeatherUpdateDelegate?
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let context = context {
            cities = context[Constants.cityListKey] as! [City]
            cities = CityHelper.sortCityList(cities)
            delegate = context["delegate"] as? WeatherUpdateDelegate
            
            cityTable.setNumberOfRows(cities.count, withRowType: "CityRow")
            
            for index in 0..<cityTable.numberOfRows {
                if let controller = cityTable.rowControllerAtIndex(index) as? CityRowController {
                    controller.cityLabel.setText(CityHelper.cityName(cities[index]))
                }
            }
        }
    }
    
    @IBAction func cancel() {
        popController()
    }
    
    override func willActivate() {
        super.willActivate()
        cancelButton.setTitle("Cancel".localized())
        searchLabel.setText("Results".localized())
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        let city = cities[rowIndex]
        
        PreferenceHelper.addFavorite(city)
        SharedWeather.instance.flushWrapper()
        
        if let delegate = delegate {
            SharedWeather.instance.broadcastUpdate(delegate)
        }
        
        popController()
    }
}