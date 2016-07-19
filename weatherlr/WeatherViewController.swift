//
//  WeatherViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    // MARK: outlets
    @IBOutlet weak var weatherTable: UITableView!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var warningBarButton: UIBarButtonItem!
    @IBOutlet weak var radarButton: UIBarButtonItem!
    
    var refreshControl: UIRefreshControl!
    var weatherInformationWrapper = WeatherInformationWrapper()
    var selectedCity:City?
    let maxWidth = CGFloat(600)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        weatherTable.delegate = self
        weatherTable.dataSource = self
        weatherTable.rowHeight = UITableViewAutomaticDimension
        weatherTable.estimatedRowHeight = 100.0
        weatherTable.tableHeaderView = nil
        weatherTable.backgroundColor = UIColor.clear()
        
        refreshControl = UIRefreshControl()
        refreshLabel()
        refreshControl.addTarget(self, action: #selector(WeatherViewController.refreshFromScroll(_:)), for: UIControlEvents.valueChanged)
        weatherTable.addSubview(refreshControl)
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
        let refreshControlFont = [ NSForegroundColorAttributeName: UIColor.white() ]
        let refreshLabel:String
        refreshLabel = WeatherHelper.getRefreshTime(weatherInformationWrapper)

        refreshControl.attributedTitle = AttributedString(string: refreshLabel, attributes: refreshControlFont)
        
        refreshControl.beginRefreshing()
        refreshControl.endRefreshing()
    }
    
    func refreshFromScroll(_ sender:AnyObject) {
        refresh(true)
    }
    
    func applicationWillEnterForeground(_ notification: Notification) {
        refresh(true)
    }
    
    override func viewDidLayoutSubviews() {
        decorate()
    }

    
    func refresh(_ thread: Bool) {
        if let city = PreferenceHelper.getSelectedCity() {
            self.selectedCity = city
            
            if thread {
                let priority = DispatchQueue.GlobalAttributes.qosDefault
                DispatchQueue.global(attributes: priority).async {
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
        var colorDay = UIColor(weatherColor: WeatherColor.clearDay)
        var colorNight = UIColor(weatherColor: WeatherColor.clearNight)
        
        if weatherInformationWrapper.weatherInformations.count > 0 {
            let weatherInfo = weatherInformationWrapper.weatherInformations[0]
            
            colorDay = UIColor(weatherColor: weatherInfo.color())
            
            switch weatherInfo.color() {
            case .clearDay:
                colorNight = UIColor(weatherColor: WeatherColor.clearNight)
                break
            case .snowDay:
                colorNight = UIColor(weatherColor: WeatherColor.snowNight)
                break
            case .cloudyDay:
                colorNight = UIColor(weatherColor: WeatherColor.cloudyNight)
                break
            default:
                colorNight = UIColor(weatherColor: WeatherColor.defaultColor)
            }
        }
        
        view.backgroundColor = colorDay
        gradientView.backgroundColor = colorDay
        
        gradientView.gradientWithColors(colorDay, colorNight)
        
        if view.bounds.size.width > maxWidth {
            weatherTable.bounds.size.width = maxWidth
        }
        
        if weatherInformationWrapper.alerts.count > 0 {
            warningBarButton.isEnabled = true
            warningBarButton.tintColor = UIColor.red()
        } else {
            warningBarButton.isEnabled = false
            warningBarButton.tintColor = UIColor.clear()
        }
        
        if selectedCity != nil && !selectedCity!.radarId.isEmpty {
            radarButton.isEnabled = true
            radarButton.tintColor = nil
        } else {
            radarButton.isEnabled = false
            radarButton.tintColor = UIColor.clear()
        }
    }

    func tableView(_ tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        let indexAjust = WeatherHelper.getIndexAjust(weatherInformationWrapper.weatherInformations)
        
        return weatherInformationWrapper.weatherInformations.count - indexAjust
    }
    
    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
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
        
        header.bounds.size.width = weatherTable.bounds.size.width
        
        header.gradientBackground(self.view.backgroundColor!)
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if weatherInformationWrapper.weatherInformations.count > 0 {
            let weatherInfo = weatherInformationWrapper.weatherInformations[0]
            
            if weatherInfo.weatherDay != WeatherDay.now {
                return 30
            }
        }
        
        return 130
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier  == "Settings" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let targetController = navigationController.topViewController as! SettingsViewController
            targetController.selectedCityWeatherInformation = weatherInformationWrapper.weatherInformations[0]
        } else if segue.identifier  == "ShowRadar" {
            let navigationController = segue.destinationViewController as! UINavigationController
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
            if alertText.characters.count > 30 {
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
        popoverPresentation.backgroundColor = UIColor.white()
        
        alertController.alerts = weatherInformationWrapper.alerts
        
        present(alertController, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
}

