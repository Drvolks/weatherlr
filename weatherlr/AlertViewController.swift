//
//  AlertView.swift
//  weatherlr
//
//  Created by drvolks on 2016-05-15.
//  Copyright © 2016 drvolks. All rights reserved.
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
        alertLabel.accessibilityIdentifier = "alertLabel"
        moreDetailButton.setTitle("More details".localized(), for: UIControl.State())
        moreDetailButton.accessibilityIdentifier = "moreDetailsButton"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAlertDetail" {
            guard let navigationController = segue.destination as? UINavigationController,
                  let targetController = navigationController.topViewController as? AlertDetailViewController else {
                assertionFailure("Unexpected destination for showAlertDetail segue")
                return
            }
            
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
