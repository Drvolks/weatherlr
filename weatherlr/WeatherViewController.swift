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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        weatherTable.delegate = self
        weatherTable.dataSource = self
        weatherTable.rowHeight = UITableViewAutomaticDimension
        weatherTable.estimatedRowHeight = 100.0
        weatherTable.tableHeaderView = nil
        weatherTable.backgroundColor = UIColor.clearColor()
        
        refreshControl = UIRefreshControl()
        refreshLabel()
        refreshControl.addTarget(self, action: #selector(WeatherViewController.refreshFromScroll(_:)), forControlEvents: UIControlEvents.ValueChanged)
        weatherTable.addSubview(refreshControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        
        if PreferenceHelper.getSelectedCity() != nil {
            refresh(false)
        } else {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("addCityNavigation") as! UINavigationController
                self.presentViewController(viewController, animated: false, completion: nil)
            })
        }
    }
    
    func refreshLabel() {
        let refreshControlFont = [ NSForegroundColorAttributeName: UIColor.whiteColor() ]
        let refreshLabel:String
        let dateFormatter = NSDateFormatter()
        let lang = PreferenceHelper.getLanguage()
        dateFormatter.locale = NSLocale(localeIdentifier: String(lang))
        dateFormatter.timeStyle = .ShortStyle
        refreshLabel = "Last refresh".localized() + " " + dateFormatter.stringFromDate(weatherInformationWrapper.lastRefresh)

        refreshControl.attributedTitle = NSAttributedString(string: refreshLabel, attributes: refreshControlFont)
        
        refreshControl.beginRefreshing()
        refreshControl.endRefreshing()
    }
    
    func refreshFromScroll(sender:AnyObject) {
        refresh(true)
    }
    
    func applicationWillEnterForeground(notification: NSNotification) {
        refresh(true)
    }
    
    override func viewDidLayoutSubviews() {
        decorate()
    }

    
    func refresh(thread: Bool) {
        if let city = PreferenceHelper.getSelectedCity() {
            self.selectedCity = city
            
            if thread {
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    self.weatherInformationWrapper = WeatherHelper.getWeatherInformations(city)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.displayWeather(false)
                    }
                }
            } else {
                self.weatherInformationWrapper = WeatherHelper.getWeatherInformations(city)
                displayWeather(true)
            }
        }
    }
    
    func displayWeather(foreground: Bool) {
        if weatherInformationWrapper.weatherInformations.count == 0 {
            if(foreground) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("errorNav") as! UINavigationController
                    self.presentViewController(viewController, animated: false, completion: nil)
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
        var colorDay = UIColor(weatherColor: WeatherColor.ClearDay)
        var colorNight = UIColor(weatherColor: WeatherColor.ClearNight)
        
        if weatherInformationWrapper.weatherInformations.count > 0 {
            let weatherInfo = weatherInformationWrapper.weatherInformations[0]
            
            colorDay = UIColor(weatherColor: weatherInfo.color())
            
            switch weatherInfo.color() {
            case .ClearDay:
                colorNight = UIColor(weatherColor: WeatherColor.ClearNight)
                break
            case .SnowDay:
                colorNight = UIColor(weatherColor: WeatherColor.SnowNight)
                break
            case .CloudyDay:
                colorNight = UIColor(weatherColor: WeatherColor.CloudyNight)
                break
            default:
                colorNight = UIColor(weatherColor: WeatherColor.DefaultColor)
            }
        }
        
        view.backgroundColor = colorDay
        gradientView.backgroundColor = colorDay
        
        gradientView.gradientWithColors(colorDay, colorNight)
        
        if view.bounds.size.width > maxWidth {
            weatherTable.bounds.size.width = maxWidth
        }
        
        if weatherInformationWrapper.alerts.count > 0 {
            warningBarButton.enabled = true
            warningBarButton.tintColor = UIColor.redColor()
        } else {
            warningBarButton.enabled = false
            warningBarButton.tintColor = UIColor.clearColor()
        }
        
        if selectedCity != nil && !selectedCity!.radarId.isEmpty {
            radarButton.enabled = true
            radarButton.tintColor = nil
        } else {
            radarButton.enabled = false
            radarButton.tintColor = UIColor.clearColor()
        }
    }

    func tableView(tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        let indexAjust = WeatherHelper.getIndexAjust(weatherInformationWrapper.weatherInformations)
        
        return weatherInformationWrapper.weatherInformations.count - indexAjust
    }
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("weatherCell", forIndexPath: indexPath) as! WeatherTableViewCell
        
        cell.populate(weatherInformationWrapper, indexPath: indexPath)
        
        return cell
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        weatherTable.reloadData()
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCellWithIdentifier("header")! as! WeatherHeaderCell
        
        if let city = selectedCity {
            header.populate(city, weatherInformationWrapper: weatherInformationWrapper)
        }
        
        header.bounds.size.width = weatherTable.bounds.size.width
        
        header.gradientBackground(self.view.backgroundColor!)
        
        return header
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if weatherInformationWrapper.weatherInformations.count > 0 {
            let weatherInfo = weatherInformationWrapper.weatherInformations[0]
            
            if weatherInfo.weatherDay != WeatherDay.Now {
                return 30
            }
        }
        
        return 130
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
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

    @IBAction func showAlert(sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let alertController = storyboard.instantiateViewControllerWithIdentifier("Alert") as! AlertViewController
        
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
        
        alertController.modalPresentationStyle = .Popover;
        alertController.preferredContentSize = CGSizeMake(width, height)
        
        let popoverPresentation = alertController.popoverPresentationController!
        popoverPresentation.permittedArrowDirections = .Any
        popoverPresentation.barButtonItem = sender
        popoverPresentation.delegate = self
        popoverPresentation.backgroundColor = UIColor.whiteColor()
        
        alertController.alerts = weatherInformationWrapper.alerts
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

