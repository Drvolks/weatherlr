//
//  CellHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 18-01-05.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class CellHelper {
    static func showHide(cell: UITableViewCell, offset: CGFloat, lastContentOffset: CGFloat) {
        let position = cell.frame.origin.y - offset
        let isNowCell = cell as? WeatherNowCell != nil
        let moveUp = lastContentOffset < offset
        
        var triggerPosition = CGFloat(120)
        if moveUp {
            if isNowCell {
                triggerPosition = CGFloat(0)
            }
        } else {
            triggerPosition = CGFloat(60)
            if isNowCell {
                triggerPosition = CGFloat(-50)
            }
        }

        if position <= triggerPosition && cell.alpha == 1 {
            if moveUp {
                UIView.animate(withDuration: 1, animations: {
                    cell.alpha = 0.1
                })
            } else {
                cell.alpha = 0.1
            }
        } else if position > triggerPosition && cell.alpha != 1 {
            if !moveUp {
                UIView.animate(withDuration: 1, animations: {
                    cell.alpha = 1
                })
            } else {
                cell.alpha = 1
            }
        }
    }
}
