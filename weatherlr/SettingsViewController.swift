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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        savedCities = PreferenceHelper.getFavoriteCities()
        selectedCity = PreferenceHelper.getSelectedCity()
        
        navigationItem.leftBarButtonItem = editButtonItem
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
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == citySection {
            return savedCities.count
        } else if section == langSection {
            return 2
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (indexPath as NSIndexPath).section == citySection {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if (indexPath as NSIndexPath).section == citySection {
            return UITableViewCellEditingStyle.delete
        } else {
            return UITableViewCellEditingStyle.none
        }
    }
    
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == citySection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cityCell", for: indexPath) as! CityTableViewCell
            
            let city = savedCities[(indexPath as NSIndexPath).row]
            cell.cityLabel.text = CityHelper.cityName(city)
            
            if selectedCity != nil && city.id == selectedCity!.id {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
                
                if let currentWeatherInformation = selectedCityWeatherInformation {
                    cell.weatherImage.isHidden = false
                    cell.activityIndicator.isHidden = true
                    cell.weatherImage.image = currentWeatherInformation.image()
                } else {
                    fetchWeather(cell, city: city)
                }
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                
                fetchWeather(cell, city: city)
            }
            
            return cell;
        } else if (indexPath as NSIndexPath).section == langSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "langCell", for: indexPath) as! LangTableViewCell
            
            cell.accessoryType = UITableViewCellAccessoryType.none
            
            if (indexPath as NSIndexPath).row == francaisRow {
                cell.langLabel.text = "Français"
                
                if Language.French == PreferenceHelper.getLanguage() {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                }
            } else {
                cell.langLabel.text = "English"
                
                if Language.English == PreferenceHelper.getLanguage() {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                }
            }
            
            return cell
        } else if (indexPath as NSIndexPath).section == contactSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactTableViewCell
            
            cell.contactText.text = "Contact".localized()
            cell.backgroundColor = UIColor.clear
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dataProviderCell", for: indexPath) as! DataProviderTableViewCell
            
            cell.dataProviderLabel.text = "Provider".localized()
            cell.backgroundColor = UIColor.clear
            
            return cell

        }
    }
    
    func fetchWeather(_ cell: CityTableViewCell, city: City) {
        cell.weatherImage.isHidden = true
        cell.activityIndicator.isHidden = false
        cell.activityIndicator.startAnimating()
        
        DispatchQueue.global().async {
            let weatherInformationWrapper = WeatherHelper.getWeatherInformations(city)
            
            DispatchQueue.main.async {
                cell.activityIndicator.stopAnimating()
                
                cell.activityIndicator.isHidden = true
                cell.weatherImage.isHidden = false
                
                if weatherInformationWrapper.weatherInformations.count > 0 {
                    let weatherInfo = weatherInformationWrapper.weatherInformations[0]
                    cell.weatherImage.image = weatherInfo.image()
                } else {
                    cell.weatherImage.image = UIImage(named: String(describing: WeatherStatus.blank))
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == citySection {
            return "City".localized()
        } else if section == langSection {
            return "Language".localized()
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == citySection {
            if editingStyle == .delete {
                let city = savedCities[(indexPath as NSIndexPath).row]
                
                savedCities.remove(at: (indexPath as NSIndexPath).row)
                PreferenceHelper.removeFavorite(city)
                
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == citySection {
            let city = savedCities[(indexPath as NSIndexPath).row]
            
            PreferenceHelper.addFavorite(city)
            
            dismiss(animated: true, completion: nil)
        } else {
            if (indexPath as NSIndexPath).row == francaisRow {
                PreferenceHelper.saveLanguage(Language.French)
            } else {
                PreferenceHelper.saveLanguage(Language.English)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
            
            tableView.reloadSectionIndexTitles()
            tableView.reloadData()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        // Toggles the edit button state
        super.setEditing(editing, animated: animated)
        
        if editing {
            navigationItem.leftBarButtonItem!.title = "Done".localized()
            addButton.isEnabled = false
            doneButton.isEnabled = false
        } else {
            navigationItem.leftBarButtonItem!.title = "Edit".localized()
            addButton.isEnabled = true
            doneButton.isEnabled = true
            
            libelles()
        }
    }
    
    func libelles() {
        self.title = "Settings".localized()
        // TODO à vérifier, ne fonctionne pas
        doneButton.title = "Done".localized()
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addCity" {
            selectedCityWeatherInformation = nil
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
