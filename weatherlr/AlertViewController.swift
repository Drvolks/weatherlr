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
        moreDetailButton.setTitle("More details".localized(), for: UIControlState())
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showAlertDetail" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let targetController = navigationController.topViewController as! AlertDetailViewController
            
            // pour le URL c'est toujours le même peut importe l'alerte
            targetController.alert = alerts[0]
            targetController.popOver = self
        }
    }
    
    func getTextCapitalized(_ alert: String) -> String {
        var text = alert.lowercased()
        text.replaceSubrange(text.startIndex...text.startIndex, with: String(text[text.startIndex]).uppercased())

        return text
    }
}
