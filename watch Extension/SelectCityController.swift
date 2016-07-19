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
    
    override func awake(withContext context: AnyObject?) {
        super.awake(withContext: context)
        
        if let context = context {
            cities = context[Constants.cityListKey] as! [City]
            cities = CityHelper.sortCityList(cities)
            delegate = context["delegate"] as? WeatherUpdateDelegate
            
            cityTable.setNumberOfRows(cities.count, withRowType: "CityRow")
            
            for index in 0..<cityTable.numberOfRows {
                if let controller = cityTable.rowController(at: index) as? CityRowController {
                    let city = cities[index];
                    controller.cityLabel.setText(CityHelper.cityName(city) + ", " + city.province.uppercased())
                }
            }
        }
    }
    
    @IBAction func cancel() {
        pop()
    }
    
    override func willActivate() {
        super.willActivate()
        cancelButton.setTitle("Cancel".localized())
        searchLabel.setText("Results".localized())
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let city = cities[rowIndex]
        
        PreferenceHelper.addFavorite(city)
        
        if let delegate = delegate {
            SharedWeather.instance.broadcastUpdate(delegate)
        }
        
        pop()
    }
}
