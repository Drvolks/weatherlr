//
//  WeatherHeaderCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-09.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherHeaderCell: UITableViewCell {

    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var currentTemperatureLabel: UILabel!
    @IBOutlet weak var maxTemperatureLabel: UILabel!
    @IBOutlet weak var maxTemperatureImage: UIImageView!
    @IBOutlet weak var minTemperatureLabel: UILabel!
    @IBOutlet weak var minTemperatureImage: UIImageView!
    @IBOutlet weak var daysMinMaxLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
