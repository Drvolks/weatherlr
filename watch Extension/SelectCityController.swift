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
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let dictionary = context as! Dictionary<String, AnyObject>
        cities = dictionary[Constants.cityListKey] as! [City]
        cities = CityHelper.sortCityList(cities)
            
        cityTable.setNumberOfRows(cities.count, withRowType: "CityRow")
            
        for index in 0..<cityTable.numberOfRows {
            if let controller = cityTable.rowController(at: index) as? CityRowController {
                let city = cities[index];
                controller.cityLabel.setText(CityHelper.cityName(city) + ", " + city.province.uppercased())
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
        
        pop()
    }
}
