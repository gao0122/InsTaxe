//
//  UIView+Extensions.swift
//  InsTaxe
//
//  Created by 高宇超 on 10/10/17.
//  Copyright © 2017 Yuchao. All rights reserved.
//

import UIKit

var usingNotifyLabel: Bool = false
let greenColor = UIColor(red: 93 / 255, green: 186 / 255, blue: 125 / 255, alpha: 0.92)
let orangeColor = UIColor(red: 255 / 255, green: 128 / 255, blue: 0, alpha: 0.92)

// MARK :- UIView
extension UIView {
    
    // notification (id is useless for now)
    func notifyc(text: String, color: UIColor = greenColor, duration: TimeInterval = 1.58, delay: TimeInterval = 0, nav: UINavigationController?) -> Void {
        if !usingNotifyLabel {
            usingNotifyLabel = true
            var y: CGFloat = 0
            if let nav = nav {
                y = nav.navigationBar.frame.height + nav.navigationBar.frame.origin.y
            }
            let label = UILabel(frame: CGRect(x: 0, y: y - 42, width: self.frame.size.width, height: 42))
            self.addSubview(label)
            self.bringSubview(toFront: label)
            label.minimumScaleFactor = 0.6
            label.text = "\(text)"
            label.alpha = 0
            label.textColor = .white
            label.backgroundColor = color
            label.textAlignment = .center
            label.font.withSize(10)
            if label.text == "Sorry, this page isn't available" {
                label.frame.origin.y = y
                label.layoutIfNeeded()
            }
            UIView.animate(withDuration: 0.336, delay: delay, options: [.curveEaseInOut], animations: {
                label.frame.origin.y = y
                label.alpha = 1
            }, completion: { finished in
                self.dismissNotify(label: label, delay: duration)
            })
        }
    }
    func dismissNotify(label: UILabel, delay: TimeInterval = 0) {
        UIView.animate(withDuration: 0.2, delay: delay, options: [.curveEaseOut], animations: {
            if label.text == "Sorry, this page isn't available" {
                label.alpha = 0
            } else {
                label.frame.origin.y = label.frame.origin.y - label.frame.height
                label.alpha = 0.2
            }
        }, completion: { finished in
            label.removeFromSuperview()
            usingNotifyLabel = false
        })
    }
    
}

