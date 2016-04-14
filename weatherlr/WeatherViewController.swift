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
 
        if FavoriteCityHelper.getSelectedCity() != nil {
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
        
        if let city = FavoriteCityHelper.getSelectedCity() {
            selectedCity = city
            let url = UrlHelper.getUrl(city)
        
            // TODO: do not hardcode
            if let url = NSURL(string: url) {
                if let rssParser = RssParser(url: url, language: Language.French) {
                    let rssEntries = rssParser.parse()
                    let weatherInformationProcess = RssEntryToWeatherInformation(rssEntries: rssEntries)
                    weatherInformations = weatherInformationProcess.perform()
                
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
        
        let weatherInfo = weatherInformations[indexPath.row+2]
        cell.weatherImage.image = weatherInfo.weatherStatusImage
        cell.weatherDetailLabel.text = weatherInfo.detail
        cell.backgroundColor = UIColor.clearColor()

        var minMaxImage:UIImage? = nil
        
        if weatherInfo.tendancy == Tendency.Minimum {
            minMaxImage = UIImage(named: "down")!
        } else if weatherInfo.tendancy == Tendency.Maximum {
            minMaxImage = UIImage(named: "up")!
        } else {
            minMaxImage = nil
        }
        
        cell.minMaxLabel.text = String(weatherInfo.temperature)
        cell.minMaxImage.image = minMaxImage

        if weatherInfo.weatherDay == WeatherDay.Today && !weatherInfo.night {
            // TODO: Ne pas hardcoder les labels
            cell.whenLabel.text = "Aujourd'hui"
        } else {
            cell.whenLabel.text = weatherInfo.when
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
       // UIView.animateWithDuration(0.8, animations: {
       //     cell.contentView.alpha = 1.0
      //  })
    }
    

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCellWithIdentifier("header")! as! WeatherHeaderCell
        
        // TODO: Bilingue
        if let city = selectedCity {
            header.cityLabel.text = city.frenchName
            
            var weatherInfo = weatherInformations[0]
            header.currentTemperatureLabel.text = String(weatherInfo.temperature)
            header.weatherImage.image = weatherInfo.weatherStatusImage
        
            if weatherInformations.count > 1 {
                weatherInfo = weatherInformations[1]
                
                switch weatherInfo.tendancy {
                case Tendency.Maximum:
                    //let weatherInfoNight = weatherInformations[2]
                    //header.minTemperatureLabel.text = String(weatherInfoNight.temperature)
                    header.maxTemperatureLabel.text = String(weatherInfo.temperature)
                    
                    header.maxTemperatureLabel.hidden = false
                    header.maxTemperatureImage.hidden = false
                    header.minTemperatureLabel.hidden = true
                    header.minTemperatureImage.hidden = true
                    break
                case Tendency.Minimum:
                    header.minTemperatureLabel.text = String(weatherInfo.temperature)
                    
                    header.maxTemperatureLabel.hidden = true
                    header.maxTemperatureImage.hidden = true
                    header.minTemperatureLabel.hidden = false
                    header.minTemperatureImage.hidden = false
                    break
                case Tendency.Steady:
                    if weatherInfo.night {
                        header.minTemperatureLabel.text = String(weatherInfo.temperature)
                        
                        header.minTemperatureLabel.hidden = false
                        header.minTemperatureImage.hidden = false
                        header.maxTemperatureLabel.hidden = true
                        header.maxTemperatureImage.hidden = true
                    } else {
                        //let weatherInfoNight = weatherInformations[3]
                        //header.minTemperatureLabel.text = String(weatherInfoNight.temperature)
                        header.maxTemperatureLabel.text = String(weatherInfo.temperature)
                        
                        header.maxTemperatureLabel.hidden = false
                        header.maxTemperatureImage.hidden = false
                        header.minTemperatureLabel.hidden = true
                        header.minTemperatureImage.hidden = true
                    }
                    break
                default:
                    break
                }
            } else {
                header.maxTemperatureLabel.hidden = true
                header.maxTemperatureImage.hidden = true
                header.minTemperatureLabel.hidden = true
                header.minTemperatureImage.hidden = true
            }
        }
        
        let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
        gradientMaskLayer.frame = header.bounds
        gradientMaskLayer.colors = [UIColor.whiteColor().colorWithAlphaComponent(0.95).CGColor, UIColor.whiteColor().colorWithAlphaComponent(0.5)]
        gradientMaskLayer.locations = [0.80, 1.0]
        header.layer.mask = gradientMaskLayer
        header.backgroundColor = self.view.backgroundColor!.colorWithAlphaComponent(0.95)

        return header
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 130
    }
    
}

