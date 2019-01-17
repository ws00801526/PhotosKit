//  UIKit+Ex.swift
//  Pods
//
//  Created by  XMFraker on 2019/1/16
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      UIKit_Ex

import UIKit

internal extension UIColor {
    
    convenience init(hex3: UInt16, alpha: CGFloat = 1, displayP3: Bool = false) {
        let divisor = CGFloat(15)
        let red     = CGFloat((hex3 & 0xF00) >> 8) / divisor
        let green   = CGFloat((hex3 & 0x0F0) >> 4) / divisor
        let blue    = CGFloat( hex3 & 0x00F      ) / divisor
        if displayP3, #available(iOS 10, *) {
            self.init(displayP3Red: red, green: green, blue: blue, alpha: alpha)
        } else {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
    
    convenience init(hex4: UInt16, displayP3: Bool = false) {
        let divisor = CGFloat(15)
        let red     = CGFloat((hex4 & 0xF000) >> 12) / divisor
        let green   = CGFloat((hex4 & 0x0F00) >>  8) / divisor
        let blue    = CGFloat((hex4 & 0x00F0) >>  4) / divisor
        let alpha   = CGFloat( hex4 & 0x000F       ) / divisor
        if displayP3, #available(iOS 10, *) {
            self.init(displayP3Red: red, green: green, blue: blue, alpha: alpha)
        } else {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
    
    convenience init(hex6: UInt32, alpha: CGFloat = 1, displayP3: Bool = false) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex6 & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex6 & 0x0000FF       ) / divisor
        if displayP3, #available(iOS 10, *) {
            self.init(displayP3Red: red, green: green, blue: blue, alpha: alpha)
        } else {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
    
    convenience init(hex8: UInt32, displayP3: Bool = false) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex8 & 0xFF000000) >> 24) / divisor
        let green   = CGFloat((hex8 & 0x00FF0000) >> 16) / divisor
        let blue    = CGFloat((hex8 & 0x0000FF00) >>  8) / divisor
        let alpha   = CGFloat( hex8 & 0x000000FF       ) / divisor
        if displayP3, #available(iOS 10, *) {
            self.init(displayP3Red: red, green: green, blue: blue, alpha: alpha)
        } else {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
    
    convenience init?(_ hex: String, displayP3: Bool = false) {
        let str = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "#", with: "").replacingOccurrences(of: "0x", with: "")
        let len = str.count
        guard [3, 4, 6, 8].contains(len) else { return nil }
        
        let scanner = Scanner(string: str)
        var rgba: UInt32 = 0
        guard scanner.scanHexInt32(&rgba) else { return nil }
        
        let hasAlpha = (len % 4) == 0
        if len < 5 {
            let divisor = CGFloat(15)
            let red     = CGFloat((rgba & (hasAlpha ? 0xF000 : 0xF00)) >> (hasAlpha ? 12 :  8)) / divisor
            let green   = CGFloat((rgba & (hasAlpha ? 0x0F00 : 0x0F0)) >> (hasAlpha ?  8 :  4)) / divisor
            let blue    = CGFloat((rgba & (hasAlpha ? 0x00F0 : 0x00F)) >> (hasAlpha ?  4 :  0)) / divisor
            let alpha   = hasAlpha ? CGFloat(rgba & 0x000F) / divisor : 1.0
            if displayP3, #available(iOS 10, *) {
                self.init(displayP3Red: red, green: green, blue: blue, alpha: alpha)
            } else {
                self.init(red: red, green: green, blue: blue, alpha: alpha)
            }
        } else {
            let divisor = CGFloat(255)
            let red     = CGFloat((rgba & (hasAlpha ? 0xFF000000 : 0xFF0000)) >> (hasAlpha ? 24 : 16)) / divisor
            let green   = CGFloat((rgba & (hasAlpha ? 0x00FF0000 : 0x00FF00)) >> (hasAlpha ? 16 :  8)) / divisor
            let blue    = CGFloat((rgba & (hasAlpha ? 0x0000FF00 : 0x0000FF)) >> (hasAlpha ?  8 :  0)) / divisor
            let alpha   = hasAlpha ? CGFloat(rgba & 0x000000FF) / divisor : 1.0
            if displayP3, #available(iOS 10, *) {
                self.init(displayP3Red: red, green: green, blue: blue, alpha: alpha)
            } else {
                self.init(red: red, green: green, blue: blue, alpha: alpha)
            }
        }
    }
}

internal extension UIColor {
    
    /// using for some main title, hex is 0x333333
    internal class var textBlack:       UIColor        { return #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1) }
    /// using for some tips, hex is 0x999999
    internal class var textGray:        UIColor        { return #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1) }
    
    /// using for tableView.separtor, hex is 0xDDDDDD
    internal class var separator:       UIColor        { return #colorLiteral(red: 0.8666666667, green: 0.8666666667, blue: 0.8666666667, alpha: 1) }
    /// using for bottom view, hex is 0x262E36
    internal class var darkSlateGray:   UIColor        { return #colorLiteral(red: 0.1490196078, green: 0.1803921569, blue: 0.2117647059, alpha: 1) }
}

internal extension UIImage {
    
    internal class func image(with color: UIColor, size: CGSize = CGSize(width: 1.0, height: 1.0)) -> UIImage? {
        
        guard size.width > 0, size.height > 0 else { return nil }
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
