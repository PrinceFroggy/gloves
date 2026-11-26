//
//  SecondViewController.swift
//  gloves
//
//  Created by Andrew Solesa on 2017-05-14.
//  Copyright © 2017 KSG. All rights reserved.
//

import UIKit
import GoogleMaps
//import GooglePlacePicker
import CoreLocation
import Firebase
import CoreData

extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

class SecondViewController: UIViewController, UITabBarControllerDelegate, GMSMapViewDelegate, CLLocationManagerDelegate
{
    @IBOutlet weak var mapView: GMSMapView!
    
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var voteMenuView: UIView!
    
    var currentLocation = CLLocationCoordinate2D()
    var myLocation: CLLocation?
    
    @IBOutlet weak var foodPlaceNameLabel: UILabel!
    
    var oneMenu = false
    
    var name: String?
    var placeID: String?
    var locationLatitude: String?
    var locationLongitude: String?
    
    @IBOutlet weak var noLabel: UILabel!
    @IBOutlet weak var yesLabel: UILabel!
    
    var phoneUDID: String?
    var temporaryUDID: String?
    var customUDID: String?
    
    var privateDayArray = [Day]()
    var localVoteArray = [String]()
    var privateVoteArray = [Vote]()
    
    var initateVoteTimerFlag = false
    
    var showLocationOnce = false
    
    @IBOutlet weak var handVoteButton: UIButton!
    @IBOutlet weak var gloveVoteButton: UIButton!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var currentDay: String?
    
    //var placePicker: GMSPlacePicker!
    
    //@IBOutlet weak var navigationBar: UINavigationBar!
    
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
        
        self.tabBarController?.delegate = self
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        
        // MAP
        
        //self.view.bringSubview(toFront: self.navigationBar)
        
        self.view.bringSubview(toFront: self.voteMenuView)
        self.voteMenuView.isHidden = true
        
        foodPlaceNameLabel.adjustsFontSizeToFitWidth = true
        
        mapView.isMyLocationEnabled = true
        mapView.settings.scrollGestures = true
        mapView.settings.zoomGestures = true
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
        mapView.delegate = self
        
        //Location Manager code to fetch current location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // USER
        
        let md5Data = MD5(string: UIDevice.current.identifierForVendor!.uuidString)
        
        let md5Hex =  md5Data.map { String(format: "%02hhx", $0) }.joined()
        
        self.phoneUDID = md5Hex
        
        self.temporaryUDID = (md5Hex + "@gmail.com")
        
        self.customUDID = self.temporaryUDID
        
        print(self.customUDID!)
        
        print("UDID: \(UIDevice.current.identifierForVendor!.uuidString)")
        
        FIRAuth.auth()?.createUser(withEmail: self.customUDID!, password: self.customUDID!, completion: {
            user, error in
            if error != nil
            {
                FIRAuth.auth()?.signIn(withEmail: self.customUDID!, password: self.customUDID!, completion: { (user, error) in
                    
                    if error == nil
                    {
                        self.autoLogin()
                    }
                    else if error != nil
                    {
                        print(error!)
                    }
                })
            }
            else
            {
                print("user created")
                
                self.autoLogin()
            }
        })
        
        // COREDATA
        
        print("GETTING CURRENT DATE!!!!!")
        
        self.getCurrentDate()
        
        let fetchDateRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Day")
        let fetchVoteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Vote")
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        do
        {
            privateDayArray = try managedContext.fetch(fetchDateRequest) as! [Day]
            privateVoteArray = try managedContext.fetch(fetchVoteRequest) as! [Vote]
        }
        catch
        {
            print("Fetching Failed")
        }
        
        print("PRIVATE VOTE ARRAY COUNT IS")
        
        print(privateVoteArray.count)
        
        print("LIST OF PRIVATE VOTE ARRAY ITEMS")
        
        for i in 0 ..< privateVoteArray.count
        {
            print ("Item \(i) == \(privateVoteArray[i].voteID!)")
        }
        
        if privateVoteArray.count > 0
        {
            print("COMPARING DAYS")
            
            print("CURRENT DAY = \(self.currentDay!) || PRIVATE DATE ARRAY = \(privateDayArray[0].voteDay! as! String)")
            
            if self.currentDay! == privateDayArray[0].voteDay! as! String
            {
                print("DATES ARE EQUAL")
            
                for i in 0..<privateVoteArray.count
                {
                    localVoteArray.append(privateVoteArray[i].voteID! as! String)
                }
            }
            else
            {
                print("DATE IS GREATER THAN OR LESS THAN AKA DIFFEREN'T")
                
                do
                {
                    let fetchedEntities = try managedContext.fetch(fetchVoteRequest) as! [Vote]
                    
                    for entity in fetchedEntities
                    {
                        managedContext.delete(entity)
                    }
                    
                    try managedContext.save()
                }
                catch
                {
                    print(error)
                }
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController)
    {
        let tabBarIndex = tabBarController.selectedIndex
        
        if tabBarIndex == 1
        {
            self.locationManager.startUpdatingLocation()
            
            if self.myLocation != nil
            {
                if CLLocationCoordinate2DIsValid(self.myLocation!.coordinate)
                {
                    self.mapView.camera = GMSCameraPosition.camera(withTarget: self.myLocation!.coordinate, zoom: 18)
                }
            }
        }
    }
    
    func autoLogin()
    {
        FIRAuth.auth()?.signIn(withEmail: self.customUDID!, password: self.customUDID!, completion: {
            user, error in
            if error != nil
            {
                print(error!)
            }
            else
            {
                print("login successful")
            }
        })
    }
    
    func getCurrentDate()
    {
        let today = Date()
        self.currentDay = today.toString(dateFormat: "dd")
        
        print(self.currentDay!)
        
        print("COUNT OF LOCAL VOTE ARRAY IS : \(self.localVoteArray.count)")
    }
    
    func appMovedToBackground() throws
    {
        print("App moved to background!")
        
        let fetchDateRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Day")
        let fetchVoteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Vote")
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        do
        {
            let fetchedEntities = try managedContext.fetch(fetchDateRequest) as! [Day]
            
            for entity in fetchedEntities
            {
                managedContext.delete(entity)
            }
            
            try managedContext.save()
        }
        catch
        {
            print(error)
        }
        
        do
        {
            let fetchedEntities = try managedContext.fetch(fetchVoteRequest) as! [Vote]
            
            for entity in fetchedEntities
            {
                managedContext.delete(entity)
            }
            
            try managedContext.save()
        }
        catch
        {
            print(error)
        }
        
        let newDate = NSEntityDescription.insertNewObject(forEntityName: "Day", into: managedContext) as NSManagedObject
        
        newDate.setValue(self.currentDay!, forKey: "voteDay")
        
        for vote in self.localVoteArray
        {
            let newVote = NSEntityDescription.insertNewObject(forEntityName: "Vote", into: managedContext) as NSManagedObject
            
            newVote.setValue(vote, forKey: "voteID")
        }
        
        try managedContext.save()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        self.mapView.settings.scrollGestures = SharingManager.sharedInstance.scrollingGestures
        self.mapView.settings.zoomGestures = SharingManager.sharedInstance.zoomGestures
        
        self.locationManager.startUpdatingLocation()
        
        if self.myLocation != nil
        {
            if CLLocationCoordinate2DIsValid(self.myLocation!.coordinate)
            {
                self.mapView.camera = GMSCameraPosition.camera(withTarget: self.myLocation!.coordinate, zoom: 18)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let update = change, let myLocation = update[NSKeyValueChangeKey.newKey] as? CLLocation else
        {
            print("Location not found")
            return
        }
        
        self.myLocation = myLocation
        
        if !self.showLocationOnce
        {
            print("DO ONCE")
            
            self.mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 18)
            self.showLocationOnce = true
        }
        
        if (!SharingManager.sharedInstance.moveView)
        {
            self.mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 18)
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String,
                 name: String, location: CLLocationCoordinate2D)
    {
        self.locationManager.startUpdatingLocation()
        
        self.name = name
        self.placeID = placeID
        self.locationLatitude = String(stringInterpolationSegment: location.latitude)
        self.locationLongitude = String(stringInterpolationSegment: location.longitude)
        
        let coordinate₀ = CLLocation(latitude: self.currentLocation.latitude, longitude: self.currentLocation.longitude)
        let coordinate₁ = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        let distanceInMeters = coordinate₀.distance(from: coordinate₁)
        
        if (!oneMenu)
        {
            print("distance is: \(distanceInMeters)")
            
            if (distanceInMeters <= 121)
            {
                print("Within 120 meters to place of food")
                
                self.foodPlaceNameLabel.text = name
                
                self.descriptionLabel.text = "* close enough!"
                
                self.checkIfVotedAlready(placeID: placeID)
                
                self.voteMenuView.isHidden = false
                
                self.checkIfPlaceExists(placeID: placeID)
                
                oneMenu = true
            }
            else
            {
                print("Not within 120 meters so cannot vote")
                
                self.foodPlaceNameLabel.text = name
                
                self.descriptionLabel.text = "* too far away!"
                
                self.handVoteButton.isEnabled = false
                
                self.gloveVoteButton.isEnabled = false
                
                self.voteMenuView.isHidden = false
                
                self.checkIfPlaceExists(placeID: placeID)
                
                oneMenu = true
            }
            
            print("You tapped \(name): \(placeID), \(location.latitude)/\(location.longitude)")
        }
    }
    
    func checkIfVotedAlready(placeID: String)
    {
        if localVoteArray.index(of: placeID) != nil
        {
            print("Voted already, disabling button")
            
            self.descriptionLabel.text = "* voted already!"
            
            self.handVoteButton.isEnabled = false
            
            self.gloveVoteButton.isEnabled = false
        }
        else
        {
            self.handVoteButton.isEnabled = true
            
            self.gloveVoteButton.isEnabled = true
        }
    }
    
    func checkIfPlaceExists(placeID: String)
    {
        let ref = FIRDatabase.database().reference()
        
        // PLACE
        
        ref.child("places").observeSingleEvent(of: .value, with:
            { (snapshot) in
                
                if snapshot.hasChild(placeID)
                {
                    print("place exists")
                    
                    ref.child("places").child(placeID)
                        .observeSingleEvent(of: .value, with:
                            { (snapshot) in
                            
                            let placeDict = snapshot.value as! [String: Any]
                            
                            let yes = placeDict["yes"] as! NSNumber
                            let no = placeDict["no"] as! NSNumber
                            
                            print("yes: \(yes)  no: \(no)")
                            
                            self.yesLabel.text = String(describing: yes)
                            self.noLabel.text = String(describing: no)
                            })
                }
                else
                {
                    print("place doesn't exist")
                    
                    ref.child("places").child(placeID).setValue(["name": self.name!,
                                                                 "latitude": self.locationLatitude!,
                                                                 "longitude": self.locationLongitude!,
                                                                 "yes": 0,
                                                                 "no": 0])
                    
                    self.yesLabel.text = "0"
                    self.noLabel.text = "0"
                }
        })
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D)
    {
        print("Tapped MAP")
        
        oneMenu = false
        
        self.handVoteButton.isEnabled = true
        
        self.gloveVoteButton.isEnabled = true
        
        self.voteMenuView.isHidden = true
    }
    
    //Location Manager delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations.last
        
        self.currentLocation.latitude = (location?.coordinate.latitude)!
        self.currentLocation.longitude = (location?.coordinate.longitude)!
        
        //Finally stop updating location otherwise it will come again and again in this delegate
        self.locationManager.stopUpdatingLocation()
    }
    
    @IBAction func handVoteButtonPressed(_ sender: UIButton)
    {
        self.oneMenu = false
        
        let ref = FIRDatabase.database().reference()
        
        print("no")
        
        let today = Date()
        let date = today.toString(dateFormat: "dd-MM-yyyy") + " : " + self.placeID!
        
        print("THIS IS THE FIREBASE DATE")
        print(date)
        
        // USER
        
        ref.child("users").child(self.phoneUDID!).child(date).observeSingleEvent(of: .value, with:
            { (snapshot) in
                
                ref.child("users").child(self.phoneUDID!).child(date).setValue(["name": self.name!,
                                                                                "latitude": self.locationLatitude!,
                                                                                "longitude": self.locationLongitude!,
                                                                                "no": "1"])
        })
        
        // PLACE
        
        ref.child("places").child(self.placeID!).child("no").runTransactionBlock({ (currentData:FIRMutableData!) in
            
            var value = currentData.value as? Int
            
            if value == nil
            {
                value = 0
            }
            
            currentData.value = value! + 1
            
            return FIRTransactionResult.success(withValue: currentData)
        })
        
        print("INCREASED NO BY 1")
        
        self.localVoteArray.append(self.placeID!)
        
        self.voteMenuView.isHidden = true
        
        // Thanks for voting box
        
        let alert = UIAlertController(title: "Voted", message: "Thanks for voting no gloves.", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func gloveVoteButtonPressed(_ sender: UIButton)
    {
        self.oneMenu = false
        
        let ref = FIRDatabase.database().reference()
        
        print("yes")
        
        let today = Date()
        let date = today.toString(dateFormat: "dd-MM-yyyy") + " : " + self.placeID!
        
        print("THIS IS THE FIREBASE DATE")
        print(date)
        
        // USER
        
        ref.child("users").child(self.phoneUDID!).child(date).observeSingleEvent(of: .value, with:
            { (snapshot) in
                
                ref.child("users").child(self.phoneUDID!).child(date).setValue(["name": self.name!,
                                                                                "latitude": self.locationLatitude!,
                                                                                "longitude": self.locationLongitude!,
                                                                                "yes": "1"])
        })
        
        // PLACE
        
        ref.child("places").child(self.placeID!).child("yes").runTransactionBlock({ (currentData:FIRMutableData!) in
            
            var value = currentData.value as? Int
            
            if value == nil
            {
                value = 0
            }
            
            currentData.value = value! + 1
            
            return FIRTransactionResult.success(withValue: currentData)
        })
        
        print("INCREASED YES BY 1")
        
        self.localVoteArray.append(self.placeID!)
        
        self.voteMenuView.isHidden = true
        
        // Thanks for voting box
        
        let alert = UIAlertController(title: "Voted", message: "Thanks for voting gloves.", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /*
    @IBAction func searchButtonPressed(_ sender: UIBarButtonItem)
    {
        if (self.voteMenuView.isHidden)
        {
            let center = CLLocationCoordinate2DMake((self.myLocation?.coordinate.latitude)!, (self.myLocation?.coordinate.longitude)!)
            let northEast = CLLocationCoordinate2DMake(center.latitude + 0.001, center.longitude + 0.001)
            let southWest = CLLocationCoordinate2DMake(center.latitude - 0.001, center.longitude - 0.001)
            let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
            let config = GMSPlacePickerConfig(viewport: viewport)
            self.placePicker = GMSPlacePicker(config: config)
            
            placePicker?.pickPlace(callback: { (place: GMSPlace?, error: Error?) -> Void in
                
                if let error = error
                {
                    print("Pick Place error: \(error.localizedDescription)")
                    return
                }
                
                if let place = place
                {
                    let coordinates = CLLocationCoordinate2DMake(place.coordinate.latitude, place.coordinate.longitude)
                    
                    self.mapView.animate(toLocation: coordinates)
                    
                    let alert = UIAlertController(title: "Place Found!", message: "Please click the place to vote!", preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addAction(UIAlertAction(title: "DISMISS", style: UIAlertActionStyle.default, handler: nil))
                    
                    self.present(alert, animated: true, completion: nil)
                }
                else
                {
                    print("No place selected")
                }
                })
        }
    }
    */
}

