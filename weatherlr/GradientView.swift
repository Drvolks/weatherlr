//
//  GradientView.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-23.
//  Copyright © 2016 drvolks. All rights reserved.
//

import UIKit

class GradientView: UIView {

    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
    
    func gradientWithColors(firstColor : UIColor, _ secondColor : UIColor) {
        
        let deviceScale = UIScreen.mainScreen().scale
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRectMake(0.0, 150, self.frame.size.width * deviceScale, self.frame.size.height * deviceScale)
        gradientLayer.colors = [ firstColor.CGColor, secondColor.CGColor ]
        
        self.layer.insertSublayer(gradientLayer, atIndex: 0)
    }
    
}
