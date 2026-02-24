//
//  GradientView.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-23.
//  Copyright © 2016 drvolks. All rights reserved.
//

import UIKit

class GradientView: UIView {

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    func gradientWithColors(_ firstColor : UIColor, _ secondColor : UIColor) {
        
        let deviceScale = traitCollection.displayScale
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0.0, y: 300, width: self.frame.size.width * deviceScale, height: self.frame.size.height * deviceScale)
        gradientLayer.colors = [ firstColor.cgColor, secondColor.cgColor ]
        
        self.layer.sublayers = nil
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
}
