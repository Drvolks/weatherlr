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
        
        var triggerPosition = CGFloat(100)
        var triggerPositionHalf = CGFloat(120)
        if isNowCell {
            triggerPosition = CGFloat(-100)
            triggerPositionHalf = CGFloat(0)
        }

        // full display and should be half hidden
        if position <= triggerPositionHalf && cell.alpha == 1 {
            if moveUp {
                UIView.animate(withDuration: 1, animations: {
                    cell.alpha = 0.5
                })
            } else {
                cell.alpha = 0.5
            }
        // half display and should be hidden
        } else if position <= triggerPosition && cell.alpha == 0.5 {
            if moveUp {
                UIView.animate(withDuration: 1, animations: {
                        cell.alpha = 0
                })
            } else {
                cell.alpha = 0
            }
        // hidden and should be half displayed
        } else if position > triggerPosition && cell.alpha == 0 {
            if !moveUp {
                UIView.animate(withDuration: 1, animations: {
                    cell.alpha = 0.5
                })
            } else {
                cell.alpha = 0.5
            }
        } else if position > triggerPositionHalf && cell.alpha == 0.5 {
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
