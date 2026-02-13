//
//  AlertView.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-15.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class AlertViewController: UIViewController {

    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var moreDetailButton: UIButton!

    var alerts = [AlertInformation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var alertTexts = ""
        for i in 0..<alerts.count {
            let text = getTextCapitalized(alerts[i].alertText)
            
            if !alertTexts.isEmpty {
                alertTexts = alertTexts + "\n"
            }
            
            alertTexts = alertTexts + text
        }

        alertLabel.text = alertTexts
        moreDetailButton.setTitle("More details".localized(), for: UIControl.State())
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAlertDetail" {
            let navigationController = segue.destination as! UINavigationController
            let targetController = navigationController.topViewController as! AlertDetailViewController
            
            targetController.alerts = alerts
            targetController.popOver = self
        }
    }
    
    func getTextCapitalized(_ alert: String) -> String {
        var text = alert.lowercased()
        text.replaceSubrange(text.startIndex...text.startIndex, with: String(text[text.startIndex]).uppercased())

        return text
    }
}
