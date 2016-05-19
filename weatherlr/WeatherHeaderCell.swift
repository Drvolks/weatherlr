//
//  WeatherHeaderCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-09.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherHeaderCell: UITableViewCell {

    @IBOutlet weak var cityLabel: VerticalTopAlignLabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var currentTemperatureLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var temperatureImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
