//
//  RequestDetailViewController.swift
//  ParseStarterProject-Swift
//
//  Created by WFR-MacBook on 8/21/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit
import CoreLocation

class RequestDetailViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var map: MKMapView!
    
    let locationManager = CLLocationManager()
    let requestLatitude = requestsLocationArray[clickedRow].latitude
    let requestLongitude = requestsLocationArray[clickedRow].longitude
    
    @IBAction func acceptRequest(_ sender: Any) {
        let query = PFQuery(className: "Requests")
        query.whereKey("userId", equalTo: requestsUserIdArray[clickedRow])
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                self.createAlert(message: (error?.localizedDescription)! + "\nPlease try again later.", error: true)
            } else {
                if let requests = objects {
                    for request in requests {
                        print(request["username"])
                        request["driver"] = PFUser.current()?.objectId
                        requestsArray.remove(at: clickedRow)
                        requestsUserIdArray.remove(at: clickedRow)
                        requestsLocationArray.remove(at: clickedRow)
                        request.saveInBackground(block: { (success, error) in
                            if error != nil {
                                self.createAlert(message: (error?.localizedDescription)! + "\nPlease try again later.", error: true)
                            } else {
                                let coordinate = CLLocationCoordinate2DMake(self.requestLatitude, self.requestLongitude)
                                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
                                mapItem.name = "Request Location"
                                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
                            }
                        })
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let location = CLLocationCoordinate2D(latitude: requestLatitude, longitude: requestLongitude)
        let latDelta: CLLocationDegrees = 0.05
        let lonDelta: CLLocationDegrees = 0.05
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let region = MKCoordinateRegion(center: location, span: span)
        map.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.title = "Request Location"
        annotation.coordinate = location
        map.addAnnotation(annotation)
        
        print(clickedRow)
        print(requestsUserIdArray)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            let location = locations[0]
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            let userLocation = PFGeoPoint(latitude: latitude, longitude: longitude)
            PFUser.current()?["location"] = userLocation
            PFUser.current()?.saveInBackground()
        }
    }
    
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

}
