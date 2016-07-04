//
//  SettingsViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var cityTable: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var savedCities = [City]()
    var selectedCity:City?
    var selectedCityWeatherInformation:WeatherInformation?
    
    let citySection = 0
    let langSection = 1
    let contactSection = 2
    let dataProviderSection = 3
    let francaisRow = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        savedCities = PreferenceHelper.getFavoriteCities()
        selectedCity = PreferenceHelper.getSelectedCity()
        
        navigationItem.leftBarButtonItem = editButtonItem()
        setEditing(false, animated: false)
        
        // TODO: remove
        //let downloader = CityDownloader(outputPath: "/Users/jfdufour/Desktop/cities")
        //downloader.process()

        cityTable.estimatedRowHeight = 21
        cityTable.rowHeight = UITableViewAutomaticDimension
        
        cityTable.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    @IBAction func done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == citySection {
            return savedCities.count
        } else if section == langSection {
            return 2
        } else {
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == citySection {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == citySection {
            return UITableViewCellEditingStyle.Delete
        } else {
            return UITableViewCellEditingStyle.None
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        if indexPath.section == citySection {
            let cell = tableView.dequeueReusableCellWithIdentifier("cityCell", forIndexPath: indexPath) as! CityTableViewCell
            
            let city = savedCities[indexPath.row]
            
            var name = city.englishName
            if(PreferenceHelper.isFrench()) {
                name = city.frenchName
            }
            cell.cityLabel.text = name
            
            if selectedCity != nil && city.id == selectedCity!.id {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                
                if let currentWeatherInformation = selectedCityWeatherInformation {
                    cell.weatherImage.hidden = false
                    cell.activityIndicator.hidden = true
                    cell.weatherImage.image = currentWeatherInformation.image()
                } else {
                    fetchWeather(cell, city: city)
                }
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                
                fetchWeather(cell, city: city)
            }
            
            return cell;
        } else if indexPath.section == langSection {
            let cell = tableView.dequeueReusableCellWithIdentifier("langCell", forIndexPath: indexPath) as! LangTableViewCell
            
            cell.accessoryType = UITableViewCellAccessoryType.None
            
            if indexPath.row == francaisRow {
                cell.langLabel.text = "Français"
                
                if Language.French == PreferenceHelper.getLanguage() {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                }
            } else {
                cell.langLabel.text = "English"
                
                if Language.English == PreferenceHelper.getLanguage() {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                }
            }
            
            return cell
        } else if indexPath.section == contactSection {
            let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath) as! ContactTableViewCell
            
            cell.contactText.text = "Contact".localized()
            cell.backgroundColor = UIColor.clearColor()
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("dataProviderCell", forIndexPath: indexPath) as! DataProviderTableViewCell
            
            cell.dataProviderLabel.text = "Provider".localized()
            cell.backgroundColor = UIColor.clearColor()
            
            return cell

        }
    }
    
    func fetchWeather(cell: CityTableViewCell, city: City) {
        cell.weatherImage.hidden = true
        cell.activityIndicator.hidden = false
        cell.activityIndicator.startAnimating()
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            let weatherInformationWrapper = WeatherHelper.getWeatherInformations(city)
            
            dispatch_async(dispatch_get_main_queue()) {
                cell.activityIndicator.stopAnimating()
                
                cell.activityIndicator.hidden = true
                cell.weatherImage.hidden = false
                
                if weatherInformationWrapper.weatherInformations.count > 0 {
                    let weatherInfo = weatherInformationWrapper.weatherInformations[0]
                    cell.weatherImage.image = weatherInfo.image()
                } else {
                    cell.weatherImage.image = UIImage(named: String(WeatherStatus.Blank))
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == citySection {
            return "City".localized()
        } else if section == langSection {
            return "Language".localized()
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == citySection {
            if editingStyle == .Delete {
                let city = savedCities[indexPath.row]
                
                savedCities.removeAtIndex(indexPath.row)
                PreferenceHelper.removeFavorite(city)
                
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == citySection {
            let city = savedCities[indexPath.row]
            
            PreferenceHelper.saveSelectedCity(city)
            WatchData.instance.updateCity(city)
            
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            if indexPath.row == francaisRow {
                PreferenceHelper.saveLanguage(Language.French)
            } else {
                PreferenceHelper.saveLanguage(Language.English)
            }
            
            ExpiringCache.instance.removeAllObjects()
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            tableView.reloadSectionIndexTitles()
            tableView.reloadData()
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        // Toggles the edit button state
        super.setEditing(editing, animated: animated)
        
        if editing {
            navigationItem.leftBarButtonItem!.title = "Done".localized()
            addButton.enabled = false
            doneButton.enabled = false
        } else {
            navigationItem.leftBarButtonItem!.title = "Edit".localized()
            addButton.enabled = true
            doneButton.enabled = true
            
            libelles()
        }
    }
    
    func libelles() {
        self.title = "Settings".localized()
        // TODO à vérifier, ne fonctionne pas
        doneButton.title = "Done".localized()
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addCity" {
            selectedCityWeatherInformation = nil
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
}
