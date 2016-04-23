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
    
    var weatherInformations = [WeatherInformation]()
    var selectedCity:City?
    let blankImage = UIImage(named: String(WeatherStatus.Blank))
    
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
         
        if PreferenceHelper.getSelectedCity() != nil {
            refresh()
        } else {
            let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("addCity") as UIViewController
            self.presentViewController(viewController, animated: false, completion: nil)
        }
    }
    
    func applicationWillEnterForeground(notification: NSNotification) {
        refresh()
    }

    
    func refresh() {
        weatherInformations.removeAll()
        
        if let city = PreferenceHelper.getSelectedCity() {
            selectedCity = city
            let url = UrlHelper.getUrl(city)
        
            if let url = NSURL(string: url) {
                if let rssParser = RssParser(url: url, language: PreferenceHelper.getLanguage()) {
                    let rssEntries = rssParser.parse()
                    let weatherInformationProcess = RssEntryToWeatherInformation(rssEntries: rssEntries)
                    weatherInformations = weatherInformationProcess.perform()
                
                    let weatherInfo = weatherInformations[0]
                    self.view.backgroundColor = weatherInfo.color()
                    
                    weatherTable.reloadData()
                }
            }
        }
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

        cell.whenLabel.text = weatherInfo.when

        if weatherInfo.weatherDay == WeatherDay.Today {
            cell.minMaxLabel.hidden = true
            cell.minMaxImage.hidden = true
            
            if !weatherInfo.night {
                cell.whenLabel.text = "Today".localized()
            }
        } else {
            cell.minMaxLabel.text = String(weatherInfo.temperature)
            cell.minMaxImage.image = getMinMaxImage(weatherInfo, header: false)
            
            cell.minMaxLabel.hidden = false
            cell.minMaxImage.hidden = false
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
       // UIView.animateWithDuration(0.8, animations: {
       //     cell.contentView.alpha = 1.0
      //  })
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
            
            var weatherInfo = weatherInformations[0]
            header.currentTemperatureLabel.text = String(weatherInfo.temperature)
            
            if(weatherInfo.image() == blankImage) {
                header.weatherImage.hidden = true
            } else {
                header.weatherImage.image = weatherInfo.image()
                header.weatherImage.hidden = false
            }
            
            if weatherInformations.count > 1 {
                weatherInfo = weatherInformations[1]
                
                header.temperatureLabel.text = String(weatherInfo.temperature)
                header.temperatureImage.image = getMinMaxImage(weatherInfo, header: true)
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
}

