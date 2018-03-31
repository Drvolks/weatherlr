//
//  WeatherViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit
import MapKit

#if FREE
    import GoogleMobileAds
#endif

class WeatherViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, CLLocationManagerDelegate {
    // MARK: outlets
    @IBOutlet weak var weatherTable: UITableView!
    @IBOutlet weak var warningBarButton: UIBarButtonItem!
    @IBOutlet weak var radarButton: UIBarButtonItem!
    #if FREE
        @IBOutlet weak var googleBannerView: GADBannerView!
    #else
        @IBOutlet weak var googleBannerView: UIView!
    #endif
    @IBOutlet weak var googleBannerHeightConstraint: NSLayoutConstraint!
    
    var refreshControl: UIRefreshControl!
    var weatherInformationWrapper = WeatherInformationWrapper()
    var selectedCity:City?
    let maxWidth = CGFloat(600)
    var lastContentOffset: CGFloat = 0
    var allCityList = [City]()
    var currentLocationActivated = false
    let locationServices = LocationServices()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = Bundle.main.path(forResource: "Cities", ofType: "plist")
        allCityList = (NSKeyedUnarchiver.unarchiveObject(withFile: path!) as? [City])!
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        #if FREE
            googleBannerView.adUnitID = Constants.googleAddId
            googleBannerView.rootViewController = self
            let googleRequest = GADRequest()
            #if DEBUG
                googleRequest.testDevices = [kGADSimulatorID, "9daac87965735d59a75181ae69755337"]
            #endif
            googleBannerView.load(googleRequest)
            googleBannerView.isHidden = false
            googleBannerHeightConstraint.constant = 50
        #endif
        
        weatherTable.delegate = self
        weatherTable.dataSource = self
        weatherTable.rowHeight = UITableViewAutomaticDimension
        weatherTable.estimatedRowHeight = 100.0
        weatherTable.backgroundColor = UIColor.clear
        
        refreshControl = UIRefreshControl()
        refreshLabel()
        refreshControl.addTarget(self, action: #selector(refreshFromScroll(_:)), for: UIControlEvents.valueChanged)
        weatherTable.addSubview(refreshControl)

        NotificationCenter.default.addObserver(self, selector: #selector(willGoToBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
    }
    
    @objc func willGoToBackground() {
        if weatherTable.numberOfRows(inSection: 0) > 0 {
            let indexPath = IndexPath(row: 0, section: 0)
            weatherTable.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        if getCurrentCity() != nil {
            refresh(false)
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addCityNavigation") as! UINavigationController
                self.present(viewController, animated: false, completion: nil)
            })
        }
    }
    
    func getCurrentCity() -> City? {
        if let city = PreferenceHelper.getSelectedCity() {
            if city.id == Global.currentLocationCityId {
                self.selectedCity = city
                
                locationServices.getAdress { locationData, error in
                    if let data = locationData {
                        if let cityFound = CityHelper.searchSingleCity(data.cityName, allCityList: self.allCityList) {
                            self.currentLocationActivated = true
                            self.selectedCity = cityFound
                            self.refresh(false)
                        } else {
                            self.currentLocationActivated = false
                        }
                    }
                }
                
                return self.selectedCity
            } else {
                selectedCity = city
                return selectedCity
            }
        }
        
        selectedCity = nil
        return selectedCity
    }
    
    func refreshLabel() {
        let refreshControlFont = [ NSAttributedStringKey.foregroundColor: UIColor.white ]
        let refreshLabel:String
        refreshLabel = WeatherHelper.getRefreshTime(weatherInformationWrapper)

        refreshControl.attributedTitle = NSAttributedString(string: refreshLabel, attributes: refreshControlFont)
        
        refreshControl.beginRefreshing()
        refreshControl.endRefreshing()
    }
    
    @objc func refreshFromScroll(_ sender:AnyObject) {
        if getCurrentCity() != nil {
            refresh(true)
        }
    }
    
    @objc func applicationWillEnterForeground(_ notification: Notification) {
        var backgroundRefresh = true
        
        let previousSelectedCity = selectedCity
        
        if let city = getCurrentCity() {
            if let previousSelectedCityInitialized = previousSelectedCity {
                if previousSelectedCityInitialized.id != city.id {
                    backgroundRefresh = false
                }
            }
        }
        
        refresh(backgroundRefresh)
    }
    
    override func viewDidLayoutSubviews() {
        decorate()
    }

    
    func refresh(_ thread: Bool) {
        if let city = selectedCity {
            if city.id == Global.currentLocationCityId {
                // recherche de l'emplecement en cours
                
            } else {
                if thread {
                    DispatchQueue.global().async {
                        self.weatherInformationWrapper = WeatherHelper.getWeatherInformations(city)
                        
                        DispatchQueue.main.async {
                            self.displayWeather(false)
                        }
                    }
                } else {
                    self.weatherInformationWrapper = WeatherHelper.getWeatherInformations(city)
                    displayWeather(true)
                }
            }
        }
    }
    
    func displayUseCurrentLocationProgress() {
        
    }
    
    func displayWeather(_ foreground: Bool) {
        if weatherInformationWrapper.weatherInformations.count == 0 {
            if(foreground) {
                DispatchQueue.main.async(execute: { () -> Void in
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "errorNav") as! UINavigationController
                    self.present(viewController, animated: false, completion: nil)
                })
            }
        } else {
            refreshLabel()
            
            refreshControl.endRefreshing()
            
            self.decorate()
            
            self.weatherTable.reloadData()
        }
    }
    
    func decorate() {
        if view.bounds.size.width > maxWidth {
            weatherTable.bounds.size.width = maxWidth
        }
        
        if weatherInformationWrapper.alerts.count > 0 {
            warningBarButton.isEnabled = true
            warningBarButton.image = UIImage(named: "warning")
        } else {
            warningBarButton.isEnabled = false
            warningBarButton.image = nil
        }
        
        // TODO retirer l'image au lieu du tint
        if selectedCity != nil && !selectedCity!.radarId.isEmpty {
            radarButton.isEnabled = true
            radarButton.tintColor = nil
        } else {
            radarButton.isEnabled = false
            radarButton.tintColor = UIColor.clear
        }
    }

    func tableView(_ tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        let indexAjust = WeatherHelper.getIndexAjust(weatherInformationWrapper.weatherInformations)
        return weatherInformationWrapper.weatherInformations.count - indexAjust
    }
    
    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "weatherNowCell", for: indexPath) as! WeatherNowCell
            cell.initialize(city: selectedCity, weatherInformationWrapper: weatherInformationWrapper)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "weatherCell", for: indexPath) as! WeatherTableViewCell
        cell.initialize(weatherInformationWrapper: weatherInformationWrapper, indexPath: indexPath)
        return cell
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        weatherTable.reloadData()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCell(withIdentifier: "header")! as! WeatherHeaderCell
        header.initialize(city: selectedCity, weatherInformationWrapper: weatherInformationWrapper)
        return header
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if indexPath.row == 0 {
            if weatherInformationWrapper.weatherInformations.count > 0 {
                let weatherInfo = weatherInformationWrapper.weatherInformations[0]
                
                if weatherInfo.weatherDay == WeatherDay.now {
                    if(weatherInfo.weatherStatus != .blank) {
                        return 210
                    }
                }
            }
            
            return 0
        }
        
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 140
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier  == "Settings" {
            let navigationController = segue.destination as! UINavigationController
            let targetController = navigationController.topViewController as! SettingsViewController
            targetController.selectedCityWeatherInformation = weatherInformationWrapper.weatherInformations[0]
        } else if segue.identifier  == "ShowRadar" {
            let navigationController = segue.destination as! UINavigationController
            let targetController = navigationController.topViewController as! RadarViewController
            targetController.city = selectedCity
        }
    }

    @IBAction func showAlert(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let alertController = storyboard.instantiateViewController(withIdentifier: "Alert") as! AlertViewController
        
        var width = weatherTable.bounds.size.width - 40
        if width > 300 {
            width = 300
        }
        var lines = weatherInformationWrapper.alerts.count
        for i in 0..<weatherInformationWrapper.alerts.count {
            let alertText = weatherInformationWrapper.alerts[i].alertText
            if alertText.count > 30 {
                lines = lines + 1
            }
        }
        let height = CGFloat(80 + (21*lines))
        
        alertController.modalPresentationStyle = .popover;
        alertController.preferredContentSize = CGSize(width: width, height: height)
        
        let popoverPresentation = alertController.popoverPresentationController!
        popoverPresentation.permittedArrowDirections = .any
        popoverPresentation.barButtonItem = sender
        popoverPresentation.delegate = self
        popoverPresentation.backgroundColor = UIColor.white
        
        alertController.alerts = weatherInformationWrapper.alerts
        
        present(alertController, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let indexes = weatherTable.indexPathsForVisibleRows {
            for i in 0..<indexes.count {
                let index = indexes[i]
                if let cell = weatherTable.cellForRow(at: index) {
                    CellHelper.showHide(cell: cell, offset: scrollView.contentOffset.y, lastContentOffset: self.lastContentOffset)
                }
            }
        }
    }
}

