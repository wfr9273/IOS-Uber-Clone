//
//  RequestsListTableViewController.swift
//  ParseStarterProject-Swift
//
//  Created by WFR-MacBook on 8/21/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse
import CoreLocation


var clickedRow = -1
var requestsLocationArray = [PFGeoPoint()]
var requestsUserIdArray = [""]
var requestsArray = ["No Available Request..."]

class RequestsListTableViewController: UITableViewController, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    
    // logout
    @IBAction func logout(_ sender: Any) {
        PFUser.logOut()
        performSegue(withIdentifier: "riderLogout", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        reloadTable()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return requestsArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "requestCell", for: indexPath)
        cell.textLabel?.text = requestsArray[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        clickedRow = indexPath.row
        performSegue(withIdentifier: "seeRequestDetail", sender: self)
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
    
    func reloadTable() {
        requestsArray.removeAll()
        requestsUserIdArray.removeAll()
        requestsLocationArray.removeAll()
        requestsArray.append("No Availabel Request...")
        
        let requestsQuery = PFQuery(className: "Requests")
        requestsQuery.whereKey("userId", notEqualTo: PFUser.current()?.objectId ?? "")
        requestsQuery.whereKeyDoesNotExist("driver")
        requestsQuery.findObjectsInBackground { (objects, error) in
            if error != nil {
                self.createAlert(message: (error?.localizedDescription)!, error: true)
            } else {
                if (objects?.count)! > 0 {
                    requestsArray.removeAll()
                    if let requests = objects {
                        for object in requests {
                            let requestUsername = object["username"] as! String
                            let requestUserId = object["userId"] as! String
                            let driverLocation = PFUser.current()?["location"] as! PFGeoPoint
                            
                            let userQuery = PFUser.query()
                            userQuery?.whereKey("objectId", equalTo: object["userId"])
                            userQuery?.findObjectsInBackground(block: { (objects, error) in
                                if error != nil {
                                    self.createAlert(message: (error?.localizedDescription)!, error: true)
                                } else {
                                    if let users = objects {
                                        for user in users {
                                            let requestLocation = user["location"] as! PFGeoPoint
                                            let distance = String(format: "%.2f", requestLocation.distanceInMiles(to: driverLocation))
                                            requestsArray.append(requestUsername + " - " + distance + " Miles away")
                                            requestsUserIdArray.append(requestUserId)
                                            requestsLocationArray.append(requestLocation)
                                            self.tableView.reloadData()
                                        }
                                    }
                                }
                            })
                        }
                    }
                } else {
                    self.tableView.reloadData()
                }
            }
        }
    }
}
