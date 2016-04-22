//
//  ContactTableViewCell.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-22.
//  Copyright © 2016 drvolks. All rights reserved.
//

import UIKit

class ContactTableViewCell: UITableViewCell {
    @IBOutlet weak var contactText: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
