//
//  RegisterViewController.swift
//  gloves
//
//  Created by Andrew Solesa on 2017-08-17.
//  Copyright © 2017 KSG. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreData

class RegisterViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var genderTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    
    @IBOutlet weak var genderPickerView: UIPickerView!
    @IBOutlet weak var agePickerView: UIPickerView!
    
    var genderArray = ["Male", "Female", "Other"]
    var ageArray = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", "93", "94", "95", "96", "97", "98", "99"]
    
    var phoneUDID: String?
    
    func MD5(string: String) -> Data {
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        
        let md5Data = MD5(string: UIDevice.current.identifierForVendor!.uuidString)
        
        let md5Hex =  md5Data.map { String(format: "%02hhx", $0) }.joined()
        
        self.phoneUDID = md5Hex
        
        genderPickerView.isHidden = true
        agePickerView.isHidden = true
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if (pickerView.tag == 1)
        {
            return genderArray.count
        }
        else
        {
            return ageArray.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
            if (pickerView.tag == 1)
            {
                return "\(genderArray[row])"
            }
            else
            {
                return "\(ageArray[row])"
            }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if (pickerView.tag == 1)
        {
            genderTextField.text = genderArray[row]
            genderPickerView.isHidden = true
        }
        else
        {
            ageTextField.text = ageArray[row]
            agePickerView.isHidden = true
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        if (textField.tag == 1)
        {
            if (agePickerView.isHidden)
            {
                genderPickerView.isHidden = false
            }
        }
        else
        {
            if (genderPickerView.isHidden)
            {
                agePickerView.isHidden = false
            }
        }
        
        return false
    }
    
    @IBAction func registerButtonPressed(_ sender: UIButton)
    {
        let ref = FIRDatabase.database().reference()
        
        if ((!(genderTextField.text?.isEmpty)!) && (!(ageTextField.text?.isEmpty)!))
        {
            //USER WITH GENDER & AGE
            
            ref.child("users").child(self.phoneUDID!).observeSingleEvent(of: .value, with:
                { (snapshot) in
            
                    ref.child("users").child(self.phoneUDID!).setValue(["gender": self.genderTextField.text!,
                                                                        "age": self.ageTextField.text!])
                    })
        }
        else if ((!(genderTextField.text?.isEmpty)!) && ((ageTextField.text?.isEmpty)!))
        {
            //USER WITH GENDER & NO AGE
            
            ref.child("users").child(self.phoneUDID!).observeSingleEvent(of: .value, with:
                { (snapshot) in
                    
                    ref.child("users").child(self.phoneUDID!).setValue(["gender": self.genderTextField.text!,
                                                                        "age": "N/A"])
            })
        }
        else if (((genderTextField.text?.isEmpty)!) && (!(ageTextField.text?.isEmpty)!))
        {
            //USER WITH NO GENDER & AGE
            
            ref.child("users").child(self.phoneUDID!).observeSingleEvent(of: .value, with:
                { (snapshot) in
                    
                    ref.child("users").child(self.phoneUDID!).setValue(["gender": "N/A",
                                                                        "age": self.ageTextField.text!])
            })
        }
        else
        {
            //USER WITH NO GENDER & NO AGE
            
            ref.child("users").child(self.phoneUDID!).observeSingleEvent(of: .value, with:
                { (snapshot) in
                    
                    ref.child("users").child(self.phoneUDID!).setValue(["gender": "N/A",
                                                                        "age": "N/A"])
            })
        }
        
        //COREDATA
        
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        let register = NSEntityDescription.insertNewObject(forEntityName: "Registered", into: managedContext) as NSManagedObject
        
        register.setValue(NSNumber(value: 1), forKey: "saveRegister")
        
        do
        {
            try managedContext.save()
            
        }
        catch
        {
            
        }
        
        //SEGUE
        
        performSegue(withIdentifier: "registeredShow", sender: self)
        
    }
}
