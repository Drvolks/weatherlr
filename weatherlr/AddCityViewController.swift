//
//  AddCityViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit
import WeatherFramework

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
    var modalDelegate:ModalDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Add City".localized()
        // TODO à vérifier, ne fonctionne pas
        cancelButton.possibleTitles = ["Cancel".localized()]
        cancelButton.title = "Cancel".localized()
        // ne fonctionne plus en iOS 13
        // searchText.setValue("Cancel".localized(), forKey:"_cancelButtonText")

        allCityList = CityHelper.loadAllCities()
        allCities = buildCityIndex(allCityList)
        allSections = buildSections(allCities)
        
        resetSearch()
        
        cityTable.delegate = self
        cityTable.dataSource = self
        searchText.delegate = self
        
        cancelButton.isEnabled = true
        
        cityTable.sectionIndexBackgroundColor = UIColor.clear
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let delegate = modalDelegate {
            delegate.refresh()
        }
    }
    
    func buildCityIndex(_ cityListToProcess: [City]) -> [String:[City]] {
        var cityDictionary = [String:[City]]()
        
        for i in 0..<cityListToProcess.count {
            let city = cityListToProcess[i]
            let name = CityHelper.cityName(city)
            let letter = (name.uppercased() as NSString).substring(to: 1)
            
            var cityListForLettre = cityDictionary[letter]
            if cityListForLettre == nil {
                cityListForLettre = [City]()
            }
            
            cityListForLettre!.append(city)
            cityDictionary[letter] = cityListForLettre
        }
        
        return sortCityIndex(cityDictionary)
    }
    
    func buildSections(_ cityDictionary : [String:[City]]) -> [Int:String] {
        let sortedKeys = cityDictionary.keys.sorted()
        var newSections = [Int:String]()
        for i in 0..<sortedKeys.count {
            let key = sortedKeys[i]
            newSections[i] = key
        }

        return newSections
    }
    
    func sortCityIndex(_ cityDictionary : [String:[City]]) -> [String:[City]] {
        var sortedCityDictionary = [String:[City]]()
        let sortedKeys = cityDictionary.keys.sorted()
        
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
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
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
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        resetSearch()
        
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
        cityTable.reloadData()
    }
    
    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

    // MARK: table
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return filteredCities.keys.sorted()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = sections[section]!
        if let sectionValues = filteredCities[key] {
            return sectionValues.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cityCell", for: indexPath) as! CityTableViewCell
        
        let city = cityRow(indexPath)
        
        cell.cityLabel.text = CityHelper.cityName(city) + ", " + city.province.uppercased()

        return cell
    }
    
    
    
    func cityRow(_ indexPath: IndexPath) -> City {
        return filteredCities[sections[(indexPath as NSIndexPath).section]!]![(indexPath as NSIndexPath).row]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let city = cityRow(indexPath)
        
        PreferenceHelper.addFavorite(city)
        
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchText.resignFirstResponder()
    }
}
