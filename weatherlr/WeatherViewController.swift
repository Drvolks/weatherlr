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
    @IBOutlet weak var currentWeatherImage: UIImageView!
    @IBOutlet weak var currentWeatherTemperature: UILabel!
    @IBOutlet weak var weatherTable: UITableView!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var maxImage: UIImageView!
    @IBOutlet weak var minImage: UIImageView!
    @IBOutlet weak var villeLabel: UILabel!
    
    var weatherInformations = [WeatherInformation]()
    
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
        
        let selectedCity = FavoriteCityHelper.getSelectedCity()!
        let url = UrlHelper.getUrl(selectedCity)
        
        // TODO: Bilingue
        villeLabel.text = selectedCity.frenchName
        
        // TODO: do not hardcode
        if let url = NSURL(string: url) {
            if let rssParser = RssParser(url: url, language: Language.French) {
                let rssEntries = rssParser.parse()
                let weatherInformationProcess = RssEntryToWeatherInformation(rssEntries: rssEntries)
                weatherInformations = weatherInformationProcess.perform()
                
                var weatherInfo = weatherInformations[0]
                currentWeatherTemperature.text = String(weatherInfo.temperature)
                currentWeatherImage.image = weatherInfo.weatherStatusImage
                
                if weatherInformations.count > 1 {
                    minLabel.hidden = false
                    minImage.hidden = false
                    
                    weatherInfo = weatherInformations[1]
                
                    switch weatherInfo.tendancy {
                    case Tendency.Maximum:
                        let weatherInfoNight = weatherInformations[2]
                        minLabel.text = String(weatherInfoNight.temperature)
                        maxLabel.text = String(weatherInfo.temperature)
                    
                        maxLabel.hidden = false
                        maxImage.hidden = false
                        break
                    case Tendency.Minimum:
                        minLabel.text = String(weatherInfo.temperature)
                    
                        maxLabel.hidden = true
                        maxImage.hidden = true
                        break
                    case Tendency.Steady:
                        if weatherInfo.night {
                            minLabel.text = String(weatherInfo.temperature)
                        } else {
                            let weatherInfoNight = weatherInformations[3]
                            minLabel.text = String(weatherInfoNight.temperature)
                        }
                        maxLabel.text = String(weatherInfo.temperature)
                    
                        maxLabel.hidden = false
                        maxImage.hidden = false
                        break
                    default:
                        break
                    }
                } else {
                    maxLabel.hidden = true
                    maxImage.hidden = true
                    minLabel.hidden = true
                    minImage.hidden = true
                }
                
                weatherTable.reloadData()
            } else {
                //todayWeatherDetail.text = "ER2"
            }
        } else {
            //todayWeatherDetail.text = "ER3"
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
        
        if weatherInfo.tendancy == Tendency.Minimum {
            cell.minMaxImage.image = UIImage(named: "down")!
        } else if weatherInfo.tendancy == Tendency.Maximum {
            cell.minMaxImage.image = UIImage(named: "up")!
        } else {
            cell.minMaxImage.image = nil
        }
        cell.minMaxLabel.text = String(weatherInfo.temperature)
        
        if weatherInfo.weatherDay == WeatherDay.Today && !weatherInfo.night {
            // TODO: Ne pas hardcoder les labels
            cell.whenLabel.text = "Aujourd'hui"
        } else {
            cell.whenLabel.text = weatherInfo.when
        }
        
        return cell
    }

}

