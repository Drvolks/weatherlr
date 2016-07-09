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
    
    var allCityList = [City]()
    var allCities = [String:[City]]()
    var filteredCityList = [City]()
    var filteredCities = [String:[City]]()
    var sections = [Int:String]()
    var allSections = [Int:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Add City".localized()
        // TODO à vérifier, ne fonctionne pas
        cancelButton.possibleTitles = ["Cancel".localized()]
        cancelButton.title = "Cancel".localized()
        searchText.setValue("Cancel".localized(), forKey:"_cancelButtonText")
        
        let path = NSBundle.mainBundle().pathForResource("Cities", ofType: "plist")
        allCityList = (NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as? [City])!
        allCities = buildCityIndex(allCityList)
        allSections = buildSections(allCities)

        // TODO remove
        //let parser = CityParser()
        //parser.perform()
        
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
    
    func buildCityIndex(cityListToProcess: [City]) -> [String:[City]] {
        var cityDictionary = [String:[City]]()
        
        for i in 0..<cityListToProcess.count {
            let city = cityListToProcess[i]
            let name = CityHelper.cityName(city)
            let letter = (name.uppercaseString as NSString).substringToIndex(1)
            
            var cityListForLettre = cityDictionary[letter]
            if cityListForLettre == nil {
                cityListForLettre = [City]()
            }
            
            cityListForLettre!.append(city)
            cityDictionary[letter] = cityListForLettre
        }
        
        return sortCityIndex(cityDictionary)
    }
    
    func buildSections(cityDictionary : [String:[City]]) -> [Int:String] {
        let sortedKeys = cityDictionary.keys.sort()
        var newSections = [Int:String]()
        for i in 0..<sortedKeys.count {
            let key = sortedKeys[i]
            newSections[i] = key
        }

        return newSections
    }
    
    func sortCityIndex(cityDictionary : [String:[City]]) -> [String:[City]] {
        var sortedCityDictionary = [String:[City]]()
        let sortedKeys = cityDictionary.keys.sort()
        
        for i in 0..<sortedKeys.count {
            let key = sortedKeys[i]
            
            let cityListForLettre = cityDictionary[key]!
            sortedCityDictionary[key] = CityHelper.sortCityList(cityListForLettre)
        }

        return sortedCityDictionary
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        var newFilteredList = [City]()
        
        if searchText.isEmpty {
            resetSearch()
        } else {
            newFilteredList = CityHelper.searchCity(searchText, allCityList: allCityList)
            
            filteredCities = buildCityIndex(newFilteredList)
            sections = buildSections(filteredCities)
            filteredCityList = newFilteredList
        }
        cityTable.reloadData()
    }
    
    func resetSearch() {
        filteredCityList = allCityList
        filteredCities = allCities
        sections = allSections
    }
    
    // MARK: serch bar
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        resetSearch()
        
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
        cityTable.reloadData()
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
        
        cell.cityLabel.text = CityHelper.cityName(city) + ", " + city.province.uppercaseString

        return cell
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
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        searchText.resignFirstResponder()
    }
}
