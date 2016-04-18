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
    
    var savedCities = [City]()
    var selectedCity:City?
    
    let citySection = 0
    let francaisRow = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        savedCities = PreferenceHelper.getFavoriteCities()
        selectedCity = PreferenceHelper.getSelectedCity()
        
        navigationItem.leftBarButtonItem = editButtonItem()
        
        // TODO: remove
        //let parser = CityParser()
        //parser.perform()

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
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == citySection {
            return savedCities.count
        } else {
            return 2
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
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
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            }
            
            return cell;
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("langCell", forIndexPath: indexPath) as! LangTableViewCell
            
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
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
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == citySection {
            return "City".localized()
        } else {
            return "Language".localized()
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == citySection {
            if editingStyle == .Delete {
                let city = savedCities[indexPath.row]
                
                savedCities.removeAtIndex(indexPath.row)
                PreferenceHelper.removeFavorite(city)
                
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            } else if editingStyle == .Insert {
                // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == citySection {
            let city = savedCities[indexPath.row]
            
            PreferenceHelper.saveSelectedCity(city)
            
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            if indexPath.row == francaisRow {
                PreferenceHelper.saveLanguage(Language.French)
            } else {
                PreferenceHelper.saveLanguage(Language.English)
            }
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            tableView.reloadSectionIndexTitles()
            tableView.reloadData()
        }
    }
    
    /*
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
