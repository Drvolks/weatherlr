//
//  WeatherTableViewCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-06.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherTableViewCell: UITableViewCell {
    @IBOutlet weak var weatherDetailLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var whenLabel: UILabel!
    @IBOutlet weak var minMaxLabel: UILabel!
    @IBOutlet weak var minMaxImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func populate(weatherInformationWrapper: WeatherInformationWrapper, indexPath: NSIndexPath) {
        let weatherInfo = weatherInformationWrapper.weatherInformations[indexPath.row+1]
        weatherImage.image = weatherInfo.image()
        weatherDetailLabel.text = weatherInfo.detail
        backgroundColor = UIColor.clearColor()
        
        if weatherInfo.weatherDay == WeatherDay.Today {
            minMaxLabel.hidden = true
            minMaxImage.hidden = true
            
            if weatherInfo.night {
                whenLabel.text = weatherInfo.when
            } else {
                whenLabel.text = "Today".localized()
            }
        } else {
            minMaxLabel.text = String(weatherInfo.temperature)
            minMaxImage.image = WeatherHelper.getMinMaxImage(weatherInfo, header: false)
            
            minMaxLabel.hidden = false
            minMaxImage.hidden = false
            
            if weatherInfo.night {
                whenLabel.text = weatherInfo.when
            } else {
                let today = NSDate()
                let theDate = addDaystoGivenDate(today, NumberOfDaysToAdd: weatherInfo.weatherDay.rawValue)
                let dateFormatter = NSDateFormatter()
                let lang = PreferenceHelper.getLanguage()
                dateFormatter.locale = NSLocale(localeIdentifier: String(lang))
                if(lang == Language.French) {
                    dateFormatter.dateFormat = "d MMMM"
                } else {
                    dateFormatter.dateFormat = "MMMM d"
                }
                
                whenLabel.text = weatherInfo.when + " " + dateFormatter.stringFromDate(theDate)
            }
        }
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
}
