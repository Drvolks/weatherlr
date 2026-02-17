//
//  SettingsViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit
import WidgetKit

class SettingsViewController: UITableViewController, @preconcurrency ModalDelegate {

    @IBOutlet weak var cityTable: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    var savedCities = [City]()
    var selectedCity:City?
    var selectedCityWeatherInformation:WeatherInformation?
    var modalDelegate:ModalDelegate?

    let citySection = 0
    let langSection = 1
    #if ENABLE_PWS
    let pwsSection = 2
    let dataProviderSection = 3
    let versionSection = 4
    #else
    let dataProviderSection = 2
    let versionSection = 3
    #endif
    let francaisRow = 1

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.leftBarButtonItem = editButtonItem
        setEditing(false, animated: false)

        cityTable.estimatedRowHeight = 21
        cityTable.rowHeight = UITableView.automaticDimension

        refresh()
    }

    func refresh() {
        savedCities = PreferenceHelper.getFavoriteCities()
        selectedCity = PreferenceHelper.getSelectedCity()

        cityTable.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let delegate = modalDelegate {
            delegate.refresh()
        }
    }

    // MARK: - Navigation
    @IBAction func done(_ sender: UIBarButtonItem) {
        WatchSyncManager.shared.syncSettings()
        dismiss(animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        #if ENABLE_PWS
        return 5
        #else
        return 4
        #endif
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == citySection {
            return savedCities.count
        } else if section == langSection {
            return 2
        } else {
            #if ENABLE_PWS
            if section == pwsSection {
                if !PreferenceHelper.hasPWSCredentials() {
                    return 0
                }
                return PreferenceHelper.getPWSStations().count + 1
            }
            #endif
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == citySection {
            let city = savedCities[indexPath.row]

            if city.id == Global.currentLocationCityId {
                return false
            }

            return true
        } else {
            #if ENABLE_PWS
            if indexPath.section == pwsSection {
                let stations = PreferenceHelper.getPWSStations()
                return indexPath.row < stations.count
            }
            #endif
            return false
        }
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == citySection {
            return UITableViewCell.EditingStyle.delete
        } else {
            #if ENABLE_PWS
            if indexPath.section == pwsSection {
                let stations = PreferenceHelper.getPWSStations()
                if indexPath.row < stations.count {
                    return UITableViewCell.EditingStyle.delete
                }
                return UITableViewCell.EditingStyle.none
            }
            #endif
            return UITableViewCell.EditingStyle.none
        }
    }

    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        if indexPath.section == citySection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cityCell", for: indexPath) as! CityTableViewCell

            let city = savedCities[indexPath.row]
            cell.cityLabel.text = CityHelper.cityName(city)

            if selectedCity != nil && city.id == selectedCity!.id {
                cell.accessoryType = UITableViewCell.AccessoryType.checkmark

                if let currentWeatherInformation = selectedCityWeatherInformation {
                    cell.weatherImage.isHidden = false
                    cell.activityIndicator.isHidden = true
                    if city.id == Global.currentLocationCityId {
                        cell.weatherImage.image = UIImage(named: String(describing: "currentLocation"))
                    } else {
                        cell.weatherImage.image = currentWeatherInformation.image()
                    }
                } else {
                    fetchWeather(cell, city: city)
                }
            } else {
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator

                fetchWeather(cell, city: city)
            }

            return cell;
        } else if indexPath.section == langSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "langCell", for: indexPath) as! LangTableViewCell

            cell.accessoryType = UITableViewCell.AccessoryType.none

            if indexPath.row == francaisRow {
                cell.langLabel.text = "Français"

                if Language.French == PreferenceHelper.getLanguage() {
                    cell.accessoryType = UITableViewCell.AccessoryType.checkmark
                }
            } else {
                cell.langLabel.text = "English"

                if Language.English == PreferenceHelper.getLanguage() {
                    cell.accessoryType = UITableViewCell.AccessoryType.checkmark
                }
            }

            return cell
        } else if indexPath.section == versionSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "versionProviderCell", for: indexPath) as! VersionProviderTableViewCell

            cell.backgroundColor = UIColor.clear

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                cell.versionLabel.text = "Version".localized() + " " + version
            } else {
                cell.versionLabel.text = ""
            }

            return cell
        } else if indexPath.section == dataProviderSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dataProviderCell", for: indexPath) as! DataProviderTableViewCell

            cell.dataProviderLabel.text = "Provider".localized()
            cell.backgroundColor = UIColor.clear

            return cell
        } else {
            #if ENABLE_PWS
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.backgroundColor = UIColor.clear
            cell.textLabel?.textColor = UIColor.label

            let stations = PreferenceHelper.getPWSStations()

            if indexPath.row < stations.count {
                let station = stations[indexPath.row]
                cell.textLabel?.text = station.name
                cell.detailTextLabel?.text = station.stationId
            } else {
                cell.textLabel?.text = "Add Station".localized()
                cell.textLabel?.textColor = UIColor.systemBlue
            }

            return cell
            #else
            return UITableViewCell()
            #endif
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

                if city.id == Global.currentLocationCityId {
                    cell.weatherImage.image = UIImage(named: String(describing: "currentLocation"))
                } else {
                    if weatherInformationWrapper.weatherInformations.count > 0 {
                        let weatherInfo = weatherInformationWrapper.weatherInformations[0]
                        cell.weatherImage.image = weatherInfo.image()
                    } else {
                        cell.weatherImage.image = UIImage(named: String(describing: WeatherStatus.blank))
                    }
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
            #if ENABLE_PWS
            if section == pwsSection {
                if !PreferenceHelper.hasPWSCredentials() {
                    return nil
                }
                return "Personal Weather Station".localized()
            }
            #endif
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == citySection {
            if editingStyle == .delete {
                let city = savedCities[indexPath.row]

                savedCities.remove(at: indexPath.row)
                PreferenceHelper.removeFavorite(city)

                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
        #if ENABLE_PWS
        if indexPath.section == pwsSection {
            if editingStyle == .delete {
                var stations = PreferenceHelper.getPWSStations()
                stations.remove(at: indexPath.row)
                PreferenceHelper.savePWSStations(stations)

                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
        #endif
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == citySection {
            let city = savedCities[indexPath.row]

            PreferenceHelper.addFavorite(city)
            WidgetCenter.shared.reloadAllTimelines()
            WatchSyncManager.shared.syncSettings()

            dismiss(animated: true, completion: nil)
        } else if indexPath.section == langSection {
            if indexPath.row == francaisRow {
                PreferenceHelper.saveLanguage(Language.French)
            } else {
                PreferenceHelper.saveLanguage(Language.English)
            }

            WidgetCenter.shared.reloadAllTimelines()

            tableView.deselectRow(at: indexPath, animated: true)

            tableView.reloadSectionIndexTitles()
            tableView.reloadData()
        } else {
            #if ENABLE_PWS
            if indexPath.section == pwsSection {
                tableView.deselectRow(at: indexPath, animated: true)
                let stations = PreferenceHelper.getPWSStations()

                if indexPath.row == stations.count {
                    showAddStationAlert()
                }
            }
            #endif
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

            let navigationController = segue.destination as! UINavigationController
            let targetController = navigationController.topViewController as! AddCityViewController
            targetController.modalDelegate = self
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    #if ENABLE_PWS
    // MARK: - PWS Helpers

    private func showAddStationAlert() {
        let alert = UIAlertController(title: "Station ID".localized(), message: "Enter station ID".localized(), preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Station ID".localized()
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
            guard let stationId = alert.textFields?.first?.text, !stationId.isEmpty else { return }
            self?.validateAndAddStation(stationId: stationId)
        })
        present(alert, animated: true)
    }

    private func validateAndAddStation(stationId: String) {
        Task {
            let observation = await PWSService.shared.fetchObservation(for: stationId)
            await MainActor.run {
                if let observation = observation {
                    let station = PWSStation(
                        stationId: stationId,
                        name: observation.neighborhood ?? stationId.capitalized,
                        latitude: observation.lat,
                        longitude: observation.lon
                    )
                    var stations = PreferenceHelper.getPWSStations()
                    // Avoid duplicates
                    stations.removeAll { $0.stationId == stationId }
                    stations.append(station)
                    PreferenceHelper.savePWSStations(stations)
                    cityTable.reloadData()
                } else {
                    let errorAlert = UIAlertController(title: nil, message: "Invalid Station".localized(), preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }
    #endif
}
