//
//  WeatherViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

#if FREE
    import GoogleMobileAds
#endif

class WeatherViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    // MARK: outlets
    @IBOutlet weak var weatherTable: UITableView!
    @IBOutlet weak var gradientView: GradientView!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        self.navigationController?.toolbar.barTintColor = UIColor(weatherColor: WeatherColor.defaultColor)
        self.navigationController?.toolbar.tintColor = UIColor.white
        
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
        
        if PreferenceHelper.getSelectedCity() != nil {
            refresh(false)
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addCityNavigation") as! UINavigationController
                self.present(viewController, animated: false, completion: nil)
            })
        }
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
        refresh(true)
    }
    
    @objc func applicationWillEnterForeground(_ notification: Notification) {
        var backgroundRefresh = true
        
        if let city = PreferenceHelper.getSelectedCity() {
            if let selectedCity = selectedCity {
                if selectedCity.id != city.id {
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
        if let city = PreferenceHelper.getSelectedCity() {
            self.selectedCity = city
            
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
        let colorDay = UIColor(weatherColor: WeatherColor.defaultColor)
        let colorNight = UIColor(weatherColor: WeatherColor.defaultColor)
        
        view.backgroundColor = colorDay
        gradientView.backgroundColor = colorDay
        
        gradientView.gradientWithColors(colorDay, colorNight)
        
        if view.bounds.size.width > maxWidth {
            weatherTable.bounds.size.width = maxWidth
        }
        
        if weatherInformationWrapper.alerts.count > 0 {
            warningBarButton.isEnabled = true
            warningBarButton.tintColor = UIColor.red
        } else {
            warningBarButton.isEnabled = false
            warningBarButton.tintColor = UIColor.clear
        }
        
        if selectedCity != nil && !selectedCity!.radarId.isEmpty {
            radarButton.isEnabled = true
            radarButton.tintColor = nil
        } else {
            radarButton.isEnabled = false
            radarButton.tintColor = UIColor.clear
        }
    }

    func tableView(_ tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        // other cells
        let indexAjust = WeatherHelper.getIndexAjust(weatherInformationWrapper.weatherInformations)
        return weatherInformationWrapper.weatherInformations.count - indexAjust
    }
    
    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "weatherNowCell", for: indexPath) as! WeatherNowCell
            
             if let city = selectedCity {
                cell.populate(city, weatherInformationWrapper: weatherInformationWrapper)
             }
            
             return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "weatherCell", for: indexPath) as! WeatherTableViewCell
            
        cell.populate(weatherInformationWrapper, indexPath: indexPath)
            
        return cell
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        weatherTable.reloadData()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCell(withIdentifier: "header")! as! WeatherHeaderCell
            
        if let city = selectedCity {
            header.populate(city, weatherInformationWrapper: weatherInformationWrapper)
        }
            
        return header
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if indexPath.row == 0 {
            if weatherInformationWrapper.weatherInformations.count > 0 {
                let weatherInfo = weatherInformationWrapper.weatherInformations[0]
                
                if weatherInfo.weatherDay == WeatherDay.now {
                    if(weatherInfo.weatherStatus != .blank) {
                        return 200
                    }
                }
            }
            
            return 0
        }
        
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
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
}

