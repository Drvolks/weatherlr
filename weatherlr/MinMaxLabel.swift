//
//  MinMaxLabel.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-11.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class MinMaxLabel: UILabel {

    let topInset = CGFloat(0), bottomInset = CGFloat(0), leftInset = CGFloat(2), rightInset = CGFloat(2)
    
    override func drawText(in rect: CGRect) {
        
        let insets: UIEdgeInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
        
    }
    override func intrinsicContentSize() -> CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize()
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }

}
