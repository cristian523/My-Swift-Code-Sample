//
//  TypeLabel.swift
//  PokeNavigator
//
//  Created by Cristian Mungiu on 26/07/16.
//  Copyright © 2016 Cristian Mungiu. All rights reserved.
//

import UIKit

extension UILabel {

    func setTypeLabel(text text: String, bgColor: String, cornerRadius: CGFloat) {
        
        self.text = text
        self.backgroundColor = UIColor(hexString: bgColor)
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }
}

extension UIColor {
    convenience init(hexString:String) {
        let hexString:NSString = hexString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let scanner = NSScanner(string: hexString as String)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
}
