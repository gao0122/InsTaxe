//
//  InsFeedTextView.swift
//  InsTaxe
//
//  Created by 高宇超 on 10/17/17.
//  Copyright © 2017 Yuchao. All rights reserved.
//

import UIKit

class InsFeedTextView: UITextView {
    
    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = self.text
        self.selectedTextRange = nil
    }
    
}
