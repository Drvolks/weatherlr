//
//  ErrorViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-24.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class ErrorViewController: UIViewController {
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var tryAgainButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorLabel.text = "Error".localized()
        tryAgainButton.title = "Try Again".localized()

        let colorDay = UIColor(weatherColor: WeatherColor.ClearDay)
        let colorNight = UIColor(weatherColor: WeatherColor.ClearNight)
        
        view.backgroundColor = colorDay
        gradientView.backgroundColor = colorDay
        
        gradientView.gradientWithColors(colorDay, colorNight)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation
    @IBAction func tryAgainClicked(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
