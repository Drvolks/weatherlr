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

        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let bgColor = isDarkMode ? UIColor(weatherColor: .nightColor) : UIColor(weatherColor: .defaultColor)

        view.backgroundColor = bgColor
        gradientView.backgroundColor = bgColor

        gradientView.gradientWithColors(bgColor, bgColor)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation
    @IBAction func tryAgainClicked(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
