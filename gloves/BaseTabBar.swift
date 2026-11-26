//
//  CustomTabBar.swift
//  gloves
//
//  Created by Andrew Solesa on 2017-05-24.
//  Copyright © 2017 KSG. All rights reserved.
//

import UIKit
import Foundation

class BaseTabBar: UITabBar
{
    override func sizeThatFits(_ size: CGSize) -> CGSize
    {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = 50
        
        return sizeThatFits
    }
}
