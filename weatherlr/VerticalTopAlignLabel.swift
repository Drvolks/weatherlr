//
//  VerticalTopAlignLabel.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-19.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class VerticalTopAlignLabel: UILabel {
    
    override func drawText(in rect: CGRect) {
        guard self.text != nil else {
            return super.drawText(in: rect)
        }
        
        let attributedText = AttributedString.init(string: self.text!, attributes: [NSFontAttributeName : self.font])
        var newRect = rect
        newRect.size.height = attributedText.boundingRect(with: rect.size, options: .usesLineFragmentOrigin, context: nil).size.height
        
        if self.numberOfLines != 0 {
            newRect.size.height = min(newRect.size.height, CGFloat(self.numberOfLines) * self.font.lineHeight)
        }
        super.drawText(in: newRect)
    }
}
