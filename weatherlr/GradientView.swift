//
//  GradientView.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-23.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class GradientView: UIView {

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    func gradientWithColors(_ firstColor : UIColor, _ secondColor : UIColor) {
        
        let deviceScale = UIScreen.main.scale
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0.0, y: 300, width: self.frame.size.width * deviceScale, height: self.frame.size.height * deviceScale)
        gradientLayer.colors = [ firstColor.cgColor, secondColor.cgColor ]
        
        self.layer.sublayers = nil
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
}
