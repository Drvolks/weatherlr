//
//  ViewController.swift
//  WeatherlrTv
//
//  Created by drvolks on 17-10-02.
//  Copyright © 2017 drvolks. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var cityLabel: UILabel!
    
    var weatherInformationWrapper = WeatherInformationWrapper()
    var selectedCity:City?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refresh() {
        // TODO remove this
        let path = Bundle.main.path(forResource: "Cities", ofType: "plist")
        let allCityList = (NSKeyedUnarchiver.unarchiveObject(withFile: path!) as? [City])!
        let cities = CityHelper.searchCity("Montreal", allCityList: allCityList)
        let city = cities[0]
        
        self.selectedCity = city
        self.weatherInformationWrapper = WeatherHelper.getWeatherInformations(city)
            
        self.cityLabel.text = city.frenchName
  
    }
}

