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
    var header:WeatherHeaderCell?
    var stackedWeatherCells = [Int: UIImageView]()
    var lastContentOffset: CGFloat = 0
    
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
        
        cell.weatherInformation = weatherInfo
        
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
                header.minTemperatureLabel.hidden = false
                header.minTemperatureImage.hidden = false
                
                weatherInfo = weatherInformations[1]
                
                switch weatherInfo.tendancy {
                case Tendency.Maximum:
                    let weatherInfoNight = weatherInformations[2]
                    header.minTemperatureLabel.text = String(weatherInfoNight.temperature)
                    header.maxTemperatureLabel.text = String(weatherInfo.temperature)
                    
                    header.maxTemperatureLabel.hidden = false
                    header.maxTemperatureImage.hidden = false
                    break
                case Tendency.Minimum:
                    header.minTemperatureLabel.text = String(weatherInfo.temperature)
                    
                    header.maxTemperatureLabel.hidden = true
                    header.maxTemperatureImage.hidden = true
                    break
                case Tendency.Steady:
                    if weatherInfo.night {
                        header.minTemperatureLabel.text = String(weatherInfo.temperature)
                    } else {
                        let weatherInfoNight = weatherInformations[3]
                        header.minTemperatureLabel.text = String(weatherInfoNight.temperature)
                    }
                    header.maxTemperatureLabel.text = String(weatherInfo.temperature)
                    
                    header.maxTemperatureLabel.hidden = false
                    header.maxTemperatureImage.hidden = false
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
        /*
        let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
        gradientMaskLayer.frame = header.bounds
        gradientMaskLayer.colors = [UIColor.whiteColor().colorWithAlphaComponent(0.95).CGColor, UIColor.whiteColor().colorWithAlphaComponent(0.5)]
        gradientMaskLayer.locations = [0.80, 1.0]
        header.layer.mask = gradientMaskLayer
 */
        header.backgroundColor = self.view.backgroundColor!.colorWithAlphaComponent(0.95)

        self.header = header
        
        return header
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 130
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var moveUp = true
        if (self.lastContentOffset > scrollView.contentOffset.y) {
            moveUp = false
        }
    
        // update the new position acquired
        self.lastContentOffset = scrollView.contentOffset.y
    
        let indexes = weatherTable.indexPathsForVisibleRows!
        if let displayedHeader = header {
            let headerBottom  = displayedHeader.frame.height + 5

            for i in 0..<indexes.count {
                let index = indexes[i]
                let currentVisibleRow = weatherTable.cellForRowAtIndexPath(index) as! WeatherTableViewCell
                let rectOfCellInTableView: CGRect = weatherTable.rectForRowAtIndexPath(index)
                let rectOfCellInSuperview: CGRect = weatherTable.convertRect(rectOfCellInTableView, toView: weatherTable.superview)
                let position = rectOfCellInSuperview.origin.y
                
                if moveUp {
                    if position <= headerBottom && stackedWeatherCells[index.row] == nil {
                        print("position \(position) for cell \(currentVisibleRow.whenLabel.text)")
                        if  displayedHeader.minMaxDaysStackView.arrangedSubviews.count == 0 {
                            // dummy label for right alignement of images
                            let label = UILabel()
                            label.text = ""
                            displayedHeader.minMaxDaysStackView.addArrangedSubview(label)
                        }
                        
                        let imageView = UIImageView()
                        imageView.image = textToImage(currentVisibleRow.minMaxLabel.text!, inImage: currentVisibleRow.minMaxImage.image!)
                        imageView.contentMode = .ScaleAspectFit
                        imageView.alpha = 0
                        imageView.addConstraint(NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 23))
                        imageView.addConstraint(NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 23))
                        
                        displayedHeader.minMaxDaysStackView.addArrangedSubview(imageView)
                        
                        UIView.animateWithDuration(0.25, animations: {
                            imageView.alpha = 1
                        })
                            
                        stackedWeatherCells[index.row] = imageView
                        
                        /*
                        UIView.animateWithDuration(0.25, animations: {
                            currentVisibleRow.minMaxImage.alpha = 0
                            currentVisibleRow.minMaxLabel.alpha = 0
                        })
                         */
                        
                        return
                    }
                } else {
                    if position > headerBottom {
                        if let imageView = stackedWeatherCells[index.row] {
                            UIView.animateWithDuration(0.25, animations: {
                                imageView.alpha = 0
                            })
                            
                            imageView.removeFromSuperview()
                            
                            stackedWeatherCells.removeValueForKey(index.row)
                            
                            /*
                            UIView.animateWithDuration(0.25, animations: {
                                currentVisibleRow.minMaxImage.alpha = 1
                                currentVisibleRow.minMaxLabel.alpha = 1
                            })
                             */
                        }
                    }
                }
            }
        }
    }
    
    func textToImage(drawText: NSString, inImage: UIImage)->UIImage{
        
        // Setup the font specific variables
        let textColor: UIColor = UIColor.whiteColor()
        let textFont: UIFont = UIFont.systemFontOfSize(32)
        
        //Setup the image context using the passed image.
        UIGraphicsBeginImageContext(inImage.size)
        
        //Setups up the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ]
        
        //Put the image into a rectangle as large as the original image.
        inImage.drawInRect(CGRectMake(0, 0, inImage.size.width, inImage.size.height))
        
        // Creating a point within the space that is as bit as the image.
        let rect: CGRect = CGRectMake(2, 2, inImage.size.width, inImage.size.height)
        
        //Now Draw the text into an image.
        drawText.drawInRect(rect, withAttributes: textFontAttributes)
        
        // Create a new image out of the images we have created
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the context now that we have the image we need
        UIGraphicsEndImageContext()
        
        //And pass it back up to the caller.
        return newImage
        
    }
}

