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
    
    var cities = [City]()
    var filteredCities = [City]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = NSBundle.mainBundle().pathForResource("Cities", ofType: "plist")
        cities = (NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as? [City])!
        // TODO: bilingue
        cities.sortInPlace({ $0.frenchName < $1.frenchName })
        filteredCities = cities
        
        cityTable.delegate = self
        cityTable.dataSource = self
        searchText.delegate = self
        
        let selectedCity = NSUserDefaults.standardUserDefaults().objectForKey(Constants.selectedCityKey)
        if selectedCity == nil {
            cancelButton.enabled = false
        } else {
            cancelButton.enabled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredCities = [City]()
        
        if searchText.isEmpty && filteredCities.count < cities.count {
            filteredCities = cities
            cityTable.reloadData()
        } else {
            for i in 0..<cities.count {
                let city = cities[i]
                // TODO: bilingue
                if city.frenchName.containsString(searchText) {
                    filteredCities.append(city)
                }
            }
        }
        
        cityTable.reloadData()
    }
    
    // MARK: serch bar
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        if filteredCities.count < cities.count {
            filteredCities = cities
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
    func tableView(tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCities.count
    }
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cityCell", forIndexPath: indexPath) as! CityTableViewCell
        
        let city = filteredCities[indexPath.row]
        // TODO: bilingue
        cell.cityLabel.text = city.frenchName + ", " + city.province.uppercaseString

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let city = filteredCities[indexPath.row]
        
        PreferenceHelper.addFavorite(city)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
