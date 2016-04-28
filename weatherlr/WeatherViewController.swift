//
//  WeatherViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: outlets
    @IBOutlet weak var weatherTable: UITableView!
    @IBOutlet weak var gradientView: GradientView!
    
    var refreshControl: UIRefreshControl!
    var weatherInformations = [WeatherInformation]()
    var selectedCity:City?
    var lastRefresh:NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        
        weatherTable.delegate = self
        weatherTable.dataSource = self
        weatherTable.rowHeight = UITableViewAutomaticDimension
        weatherTable.estimatedRowHeight = 100.0
        weatherTable.tableHeaderView = nil
        weatherTable.backgroundColor = UIColor.clearColor()
        
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshLabel()
            refreshControl.addTarget(self, action: #selector(WeatherViewController.refreshFromScroll(_:)), forControlEvents: UIControlEvents.ValueChanged)
            weatherTable.addSubview(refreshControl)
        }
        
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
        if lastRefresh != nil {
            let dateFormatter = NSDateFormatter()
            let lang = PreferenceHelper.getLanguage()
            dateFormatter.locale = NSLocale(localeIdentifier: String(lang))
            dateFormatter.timeStyle = .ShortStyle
            refreshLabel = "Last refresh".localized() + " " + dateFormatter.stringFromDate(lastRefresh!)
        } else {
            refreshLabel = "Refreshing".localized()
        }
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
                    self.weatherInformations = WeatherHelper.getWeatherInformations(city)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.displayWeather(false)
                    }
                }
            } else {
                self.weatherInformations = WeatherHelper.getWeatherInformations(city)
                displayWeather(true)
            }
        }
    }
    
    func displayWeather(foreground: Bool) {
        if self.weatherInformations.count == 0 {
            if(foreground) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("errorNav") as! UINavigationController
                    self.presentViewController(viewController, animated: false, completion: nil)
                })
            }
        } else {
            lastRefresh = NSDate()
            refreshLabel()
            
            refreshControl.endRefreshing()
            
            self.decorate()
            
            self.weatherTable.reloadData()
        }
    }
    
    func decorate() {
        var colorDay = UIColor(weatherColor: WeatherColor.ClearDay)
        var colorNight = UIColor(weatherColor: WeatherColor.ClearNight)
        
        if weatherInformations.count > 0 {
            let weatherInfo = weatherInformations[0]
            
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
    }

    func tableView(tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        return weatherInformations.count - 2
    }
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("weatherCell", forIndexPath: indexPath) as! WeatherTableViewCell
        
        let weatherInfo = weatherInformations[indexPath.row+1]
        cell.weatherImage.image = weatherInfo.image()
        cell.weatherDetailLabel.text = weatherInfo.detail
        cell.backgroundColor = UIColor.clearColor()

        if weatherInfo.weatherDay == WeatherDay.Today {
            cell.minMaxLabel.hidden = true
            cell.minMaxImage.hidden = true
            
            if weatherInfo.night {
                cell.whenLabel.text = weatherInfo.when
            } else {
                cell.whenLabel.text = "Today".localized()
            }
        } else {
            cell.minMaxLabel.text = String(weatherInfo.temperature)
            cell.minMaxImage.image = getMinMaxImage(weatherInfo, header: false)
            
            cell.minMaxLabel.hidden = false
            cell.minMaxImage.hidden = false
            
            if weatherInfo.night {
                cell.whenLabel.text = weatherInfo.when
            } else {
                let today = NSDate()
                let theDate = addDaystoGivenDate(today, NumberOfDaysToAdd: weatherInfo.weatherDay.rawValue - 1)
                let dateFormatter = NSDateFormatter()
                let lang = PreferenceHelper.getLanguage()
                dateFormatter.locale = NSLocale(localeIdentifier: String(lang))
                if(lang == Language.French) {
                    dateFormatter.dateFormat = "d MMMM"
                } else {
                    dateFormatter.dateFormat = "MMMM d"
                }
                
                cell.whenLabel.text = weatherInfo.when + " " + dateFormatter.stringFromDate(theDate)
            }
        }
        
        return cell
    }
    
    func addDaystoGivenDate(baseDate:NSDate,NumberOfDaysToAdd:Int)->NSDate
    {
        let dateComponents = NSDateComponents()
        let CurrentCalendar = NSCalendar.currentCalendar()
        let CalendarOption = NSCalendarOptions()
        
        dateComponents.day = NumberOfDaysToAdd
        
        let newDate = CurrentCalendar.dateByAddingComponents(dateComponents, toDate: baseDate, options: CalendarOption)
        return newDate!
    }

    func getMinMaxImage(weatherInfo: WeatherInformation, header: Bool) -> UIImage? {
        var name = "up"
        
        if weatherInfo.tendancy == Tendency.Minimum {
            name = "down"
        } else if weatherInfo.tendancy == Tendency.Steady {
            if weatherInfo.night {
                name = "down"
            }
        }
        
        if header {
            return UIImage(named: name + "Header")
        } else {
            return UIImage(named: name)
        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        weatherTable.reloadData()
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCellWithIdentifier("header")! as! WeatherHeaderCell
        
        if let city = selectedCity {
            var name = city.englishName
            if PreferenceHelper.isFrench() {
                name = city.frenchName
            }
            header.cityLabel.text = name
            
            if weatherInformations.count > 0 {
                var weatherInfo = weatherInformations[0]
                header.currentTemperatureLabel.text = String(weatherInfo.temperature)
                
                if(weatherInfo.weatherStatus == .Blank) {
                    header.weatherImage.hidden = true
                } else {
                    header.weatherImage.image = weatherInfo.image()
                    header.weatherImage.hidden = false
                }
                
                if weatherInformations.count > 1 {
                    weatherInfo = weatherInformations[1]
                    
                    header.temperatureLabel.hidden = false
                    header.temperatureImage.hidden = false
                    header.temperatureLabel.text = String(weatherInfo.temperature)
                    header.temperatureImage.image = getMinMaxImage(weatherInfo, header: true)
                } else {
                    header.temperatureLabel.text = ""
                    header.temperatureLabel.hidden = true
                    header.temperatureImage.hidden = true
                }
            }
        }
        
        header.bounds.size.width = weatherTable.bounds.size.width
        
        let color = self.view.backgroundColor!
        let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
        gradientMaskLayer.frame = header.bounds
        gradientMaskLayer.colors = [color.colorWithAlphaComponent(0.95).CGColor, color.colorWithAlphaComponent(0)]
        gradientMaskLayer.locations = [0.70, 1.0]
        header.layer.mask = gradientMaskLayer
        header.backgroundColor = color.colorWithAlphaComponent(0.95)
        
        return header
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 130
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Settings" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let targetController = navigationController.topViewController as! SettingsViewController
            targetController.selectedCityWeatherInformation = weatherInformations[0]
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

