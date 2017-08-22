//
//  RiderViewController.swift
//  ParseStarterProject-Swift
//
//  Created by WFR-MacBook on 8/21/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit
import CoreLocation

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet var callCancelButton: UIButton!
    @IBOutlet var requestResultLabel: UILabel!
    @IBOutlet var map: MKMapView!
    
    var requestMade = false
    let locationManager = CLLocationManager()
    var timer = Timer()
    let uberRequest = PFObject(className: "Requests")
    
    // logout
    @IBAction func logout(_ sender: Any) {
        PFUser.logOut()
        timer.invalidate()
        performSegue(withIdentifier: "riderLogout", sender: self)
    }
    
    // make a request or cancel a request
    @IBAction func callCancelUber(_ sender: Any) {
        if requestMade {
            // cancel the request
            callCancelButton.setTitle("Call an Uber", for: [])
            let query = PFQuery(className: "Requests")
            query.whereKey("userId", equalTo: PFUser.current()?.objectId ?? "")
            query.findObjectsInBackground(block: { (objects, error) in
                if error != nil {
                    self.createAlert(message: ((error?.localizedDescription)! + "\nPlease try again later."), error: true)
                } else {
                    if (objects?[0]["driver"] != nil) {
                        // if the request has been accepted, the user can not cancel it
                        self.createAlert(message: "Request has been accepted. Can not cancel.", error: true)
                    } else {
                        // cancel the request
                        let request = objects?[0]
                        request?.deleteInBackground()
                        self.requestResultLabel.text = ""
                        self.timer.invalidate()
                        self.createAlert(message: "Request has been canceled.", error: false)
                    }
                }
            })
        } else {
            // make an request
            callCancelButton.setTitle("Cancel the request", for: [])
            uberRequest["userId"] = PFUser.current()?.objectId
            uberRequest["username"] = PFUser.current()?.username
            uberRequest.saveInBackground(block: { (success, error) in
                if error != nil {
                    self.createAlert(message: ((error?.localizedDescription)! + "\nPlease try again later."), error: true)
                } else {
                    self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateDriver), userInfo: nil, repeats: true)
                    self.createAlert(message: "Request made", error: false)
                }
            })
            
        }
        requestMade = !requestMade
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // check if the current user already made a request
        let query = PFQuery(className: "Requests")
        query.whereKey("userId", equalTo: PFUser.current()?.objectId ?? "")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                self.createAlert(message: (error?.localizedDescription)!, error: true)
            } else {
                if (objects?.count)! > 0 {
                    self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateDriver), userInfo: nil, repeats: true)
                    self.uberRequest["username"] = objects?[0]["username"]
                    self.uberRequest["userId"] = objects?[0]["userId"]
                    self.uberRequest["driver"] = objects?[0]["driver"]
                    self.callCancelButton.setTitle("Cancel the request", for: [])
                    self.requestMade = true
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // get the user's current location and add annotation to the map
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            let location = locations[0]
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let latDelta: CLLocationDegrees = 0.05
            let lonDelta: CLLocationDegrees = 0.05
            let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            let region: MKCoordinateRegion = MKCoordinateRegion(center: currentLocation, span: span)
            map.setRegion(region, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = "You are here"
            map.removeAnnotations(map.annotations)
            map.addAnnotation(annotation)
            
            let userLocation = PFGeoPoint(latitude: latitude, longitude: longitude)
            PFUser.current()?["location"] = userLocation
            PFUser.current()?.saveInBackground()
        }
    }
    
    // create alert to interact with user
    func createAlert(message: String, error: Bool) {
        var alert = UIAlertController()
        if error {
            alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
        } else {
            alert = UIAlertController(title: "Info", message: message, preferredStyle: UIAlertControllerStyle.alert)
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // check if the request has benn accept
    // if yes, update the driver's info
    func updateDriver() {
        if uberRequest["driver"] != nil {
            let driverQuery = PFUser.query()
            driverQuery?.whereKey("objectId", equalTo: uberRequest["driver"])
            driverQuery?.findObjectsInBackground(block: { (objects, error) in
                if (error != nil) {
                    self.createAlert(message: (error?.localizedDescription)!, error: true)
                } else {
                    let driverLocation = objects?[0]["location"] as! PFGeoPoint
                    let distance = driverLocation.distanceInMiles(to: PFUser.current()?["location"] as? PFGeoPoint)
                    if (distance > 0.1) {
                        self.requestResultLabel.text = "Driver is " + String(format: "%.2f", distance) + " miles away"
                    } else {
                        self.requestResultLabel.text = "Driver arrived."
                        self.timer.invalidate()
                    }
                }
            })
        }
    }
}
