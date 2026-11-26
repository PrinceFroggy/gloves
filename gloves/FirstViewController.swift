//
//  FirstViewController.swift
//  gloves
//
//  Created by Andrew Solesa on 2017-05-14.
//  Copyright © 2017 KSG. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func moveMapSwitch(_ sender: UISwitch)
    {
        if (sender.isOn == true)
        {
            print("moveMapOn")
            
            SharingManager.sharedInstance.moveView = false
            
            SharingManager.sharedInstance.scrollingGestures = false
            
            SharingManager.sharedInstance.zoomGestures = false
        }
        else
        {
            print("moveMapOff")
            
            SharingManager.sharedInstance.moveView = true
            
            SharingManager.sharedInstance.scrollingGestures = true
            
            SharingManager.sharedInstance.zoomGestures = true
        }
    }
}

