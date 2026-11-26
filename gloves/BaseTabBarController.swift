//
//  BaseTabBarController.swift
//  gloves
//
//  Created by Andrew Solesa on 2017-05-14.
//  Copyright © 2017 KSG. All rights reserved.
//

import Foundation
import UIKit

class BaseTabBarController: UITabBarController
{
    @IBInspectable var defaultIndex: Int = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        selectedIndex = defaultIndex
        
        UITabBar.appearance().backgroundImage = UIImage.colorForNavBar(color: .clear)
        UITabBar.appearance().shadowImage = UIImage.colorForNavBar(color: .clear)
    }
}

extension UIImage
{
    class func colorForNavBar(color: UIColor) -> UIImage
    {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        //    Or if you need a thinner border :
        //    let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 0.5)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
