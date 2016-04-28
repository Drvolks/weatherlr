//
//  AddCityViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class AddCityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var cityTable: UITableView!
    @IBOutlet weak var searchText: UISearchBar!
    @IBOutlet weak var navigationTitle: UINavigationItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    var cityList = [City]()
    var filteredCityList = [City]()
    var filteredCities = [String:[City]]()
    var sections = [Int:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Add City".localized()
        // TODO à vérifier, ne fonctionne pas
        cancelButton.possibleTitles = ["Cancel".localized()]
        cancelButton.title = "Cancel".localized()
        searchText.setValue("Cancel".localized(), forKey:"_cancelButtonText")
        
        let path = NSBundle.mainBundle().pathForResource("Cities", ofType: "plist")
        cityList = (NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as? [City])!

        resetSearch()
        
        cityTable.delegate = self
        cityTable.dataSource = self
        searchText.delegate = self
        
        let selectedCity = NSUserDefaults.standardUserDefaults().objectForKey(Constants.selectedCityKey)
        if selectedCity == nil {
            cancelButton.enabled = false
        } else {
            cancelButton.enabled = true
        }
        
        cityTable.sectionIndexBackgroundColor = UIColor.clearColor()
    }
    
    func sortCityList(cityListToSort: [City]) -> [City] {
        var newCityList = cityListToSort
        
        if PreferenceHelper.isFrench() {
            newCityList.sortInPlace({ $0.frenchName < $1.frenchName })
        } else {
            newCityList.sortInPlace({ $0.englishName < $1.englishName })
        }
        
        return newCityList
    }
    
    func buildCityIndex(cityListToProcess: [City]) -> [String:[City]] {
        var cityDictionary = [String:[City]]()
        
        for i in 0..<cityListToProcess.count {
            let city = cityListToProcess[i]
            let name = cityName(city)
            let letter = (name.uppercaseString as NSString).substringToIndex(1)
            
            var cityListForLettre = cityDictionary[letter]
            if cityListForLettre == nil {
                cityListForLettre = [City]()
            }
            
            cityListForLettre!.append(city)
            cityDictionary[letter] = cityListForLettre
        }
        
        let sortedKeys = cityDictionary.keys.sort()
        var newSections = [Int:String]()
        for i in 0..<sortedKeys.count {
            let key = sortedKeys[i]
            newSections[i] = key
            
            let cityListForLettre = cityDictionary[key]!
            cityDictionary[key] = sortCityList(cityListForLettre)
        }
        sections = newSections
        
        return cityDictionary
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        var newFilteredList = [City]()
        
        if searchText.isEmpty && filteredCityList.count < cityList.count {
            resetSearch()
        } else {
            for i in 0..<cityList.count {
                let city = cityList[i]

                let name = cityName(city)
                
                let searched = searchText.uppercaseString.stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale(localeIdentifier: "en"))
                
                if name.containsString(searched) {
                    newFilteredList.append(city)
                }
            }
            
            filteredCities = buildCityIndex(newFilteredList)
            filteredCityList = newFilteredList
        }
        cityTable.reloadData()
    }
    
    func resetSearch() {
        filteredCityList.removeAll()
        filteredCityList.appendContentsOf(cityList)
        filteredCities = buildCityIndex(cityList)
    }
    
    // MARK: serch bar
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        if filteredCityList.count < cityList.count {
            resetSearch()
            cityTable.reloadData()
        }
        
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Navigation
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

    // MARK: table
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return filteredCities.keys.sort()
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = sections[section]!
        if let sectionValues = filteredCities[key] {
            return sectionValues.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cityCell", forIndexPath: indexPath) as! CityTableViewCell
        
        let city = cityRow(indexPath)
        
        var name = city.englishName
        if(PreferenceHelper.isFrench()) {
            name = city.frenchName
        }
        cell.cityLabel.text = name + ", " + city.province.uppercaseString

        return cell
    }
    
    func cityName(city: City) -> String {
        var name = city.englishName
        if(PreferenceHelper.isFrench()) {
            name = city.frenchName
        }
        
        name = name.uppercaseString.stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale(localeIdentifier: "en"))
    
        return name
    }
    
    func cityRow(indexPath: NSIndexPath) -> City {
        return filteredCities[sections[indexPath.section]!]![indexPath.row]
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let city = cityRow(indexPath)
        
        PreferenceHelper.addFavorite(city)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
}
