//
//  CityTableViewCell.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class CityTableViewCell: UITableViewCell {

    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

       
        
        // Configure the view for the selected state
    }

}
