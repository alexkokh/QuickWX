//
//  AirportTableViewController.swift
//  QuickWX
//
//  Created by Alexander on 11/21/15.
//  Copyright © 2015 Alexander. All rights reserved.
//

import UIKit
import CoreLocation
import CoreGraphics

var airportDesc = [AirportDesc]()

class AirportTableViewController: UITableViewController, CLLocationManagerDelegate {
    typealias AirportWithDistance = (airport: Airport, distance: Double)
    let locManager = CLLocationManager()
    var nearestAirports = [Airport]()
    var curLoc: CLLocationCoordinate2D?

    @IBAction func refreshButtonTapped(sender: UIBarButtonItem) {
        refreshNearestAirports()
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    
        let pathArc = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0].path! + "/QuickWX_Airports.arc"
        
        if !NSFileManager().fileExistsAtPath(pathArc) {
            do {
                let bundle = NSBundle.mainBundle()
                let pathCsv = bundle.pathForResource("data", ofType: "")! + "/airports.csv"
                let dataStr = try NSString(contentsOfFile: pathCsv, encoding: NSUTF8StringEncoding)
                var str = dataStr.componentsSeparatedByString("\r")
            
                for i in 1..<str.count-1 {
                    var airportData = str[i].componentsSeparatedByString(",")
                
                    var lat = airportData[8].componentsSeparatedByString("-")
                    var lon = airportData[9].componentsSeparatedByString("-")
                
                    let idx = airportData[0].endIndex.advancedBy(-1)
                    let airportType = airportData[0].substringFromIndex(idx)
                
                    // don't include heliports and private aiports
                    if airportType != "H" && airportData[7] != "PR" {
                        let a = AirportDesc(code: airportData[1], name: airportData[2],
                            latDegreesStr: lat[0], latMinutesStr: lat[1], latSecondsStr: lat[2],
                            lonDegreesStr: lon[0], lonMinutesStr: lon[1], lonSecondsStr: lon[2])
                        airportDesc.append(a)
                    }
                }

                NSKeyedArchiver.archiveRootObject(airportDesc, toFile: pathArc)
            } catch {}
        } else {
            airportDesc = NSKeyedUnarchiver.unarchiveObjectWithFile(pathArc) as! [AirportDesc]
        }
        
        locManager.delegate = self
        locManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if manager == locManager
        {
            if status == .AuthorizedWhenInUse || status == .AuthorizedAlways
            {
                locManager.startUpdatingLocation()
            }
            
        }
    }
    
    func getNearestAirports(location: CLLocation, distanceNM: Double) -> [(Airport)]
    {
        var airportsList = [Airport]()
        
        for i in 0..<airportDesc.count {
            let distance = location.distanceFromLocation(airportDesc[i].Location) / MetersInNM
            if distance < distanceNM {
                var airport = Airport(description: airportDesc[i])
                airport.distance = distance
                airportsList.append(airport)
            }
        }
        
        func airportDistanceSort(a0: Airport, a1: Airport) -> Bool
        {
            if a0.distance > a1.distance {
                return false
            } else {
                return true
            }
        }
        
        return airportsList.sort(airportDistanceSort)
    }
    
    func refreshNearestAirports()
    {
        locManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        locManager.stopUpdatingLocation()
        
        if  curLoc == nil || (locations.count > 0 && curLoc != nil && curLoc!.latitude != locations[0].coordinate.latitude && curLoc!.longitude != locations[0].coordinate.longitude)
        {
            let loc = locations[0]
            curLoc = loc.coordinate
            nearestAirports.removeAll()

            nearestAirports = getNearestAirports(loc, distanceNM: 100)
            self.tableView.reloadData()
        } else {
            for i in 0..<nearestAirports.count {
                nearestAirports[i].hasRecentMETAR = false
                nearestAirports[i].hasRecentTAF = false
            }
            
            tableView.reloadData()
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        print(error)
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AirportTableViewCell", forIndexPath: indexPath) as! AirportTableViewCell
        
        let idx = indexPath.row
        
        cell.setup(nearestAirports[idx])

        return cell
    }
    
    override func viewWillAppear(animated: Bool)
    {
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return nearestAirports.count
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "Show airport info" {
            let cell = sender as! AirportTableViewCell?
            
            if cell != nil {
                let index = tableView.indexPathForCell(cell!)
                print(index?.row)
                
                let airportInfoViewController = segue.destinationViewController as! AirportInfoViewController
                airportInfoViewController.airport = nearestAirports[(index?.row)!]
                airportInfoViewController.airportsDesc = airportDesc
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Nearest", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
            }
        }
    }
}
