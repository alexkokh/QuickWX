//
//  Common.swift
//  QuickWX
//
//  Created by Alexander on 12/20/15.
//  Copyright © 2015 Alexander. All rights reserved.
//

import UIKit
import CoreLocation

let MaxHoursBeforeNow = 3
let MetersInNM = 1852.0
let FavoritesPath = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0].path! + "/favorites"

enum CompassPoint {
    init?(dir: String)
    {
        switch dir{
        case "N":
            self = .North
        case "S":
            self = .South
        case "W":
            self = .West
        case "E":
            self = .East
        default:
            return nil
        }
    }
    
    case North
    case South
    case East
    case West
}

class AirportLocator: NSObject, CLLocationManagerDelegate
{
    let locManager = CLLocationManager()
    var curLoc: CLLocationCoordinate2D?
    var callback: ((CLLocation) -> Void)?
    
    override init()
    {
        super.init()
        locManager.delegate = self
    }
    
    func refresh(callback: (CLLocation) -> Void)
    {
        self.callback = callback
        locManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        locManager.stopUpdatingLocation()
        
        if  curLoc == nil || (locations.count > 0 && curLoc != nil && curLoc!.latitude != locations[0].coordinate.latitude && curLoc!.longitude != locations[0].coordinate.longitude)
        {
            let loc = locations[0]
            curLoc = loc.coordinate
            
            if(callback != nil) {
                callback!(loc)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        print(error)
    }
}

func loadFavorites() -> [AirportDesc]
{
    var favorites: [AirportDesc]
    
    if NSFileManager().fileExistsAtPath(FavoritesPath) {
        favorites = NSKeyedUnarchiver.unarchiveObjectWithFile(FavoritesPath) as! [AirportDesc]
    } else {
        favorites = [AirportDesc]()
    }
    
    return favorites
}

func saveFavorites(favorites: [AirportDesc])
{
    NSKeyedArchiver.archiveRootObject(favorites, toFile: FavoritesPath)
}

func addToFavorites(airport: Airport)
{
    var favorites = loadFavorites()
    favorites.append(airport.desc)
    saveFavorites(favorites)
}

func deleteFromFavorites(airport: Airport)
{
    var favorites = loadFavorites()
    
    for i in 0..<favorites.count {
        if favorites[i].Code == airport.Code {
            favorites.removeAtIndex(i)
            break
        }
    }
    
    saveFavorites(favorites)
}

func setFlightCategoty(label: UILabel, flightCategory: String)
{
    label.text = flightCategory
    
    var fcColor: UIColor
    
    switch flightCategory
    {
    case "VFR":
        fcColor = UIColor(red: 0, green: 160.0/255, blue: 70.0/255, alpha: 1)
    case "MVFR":
        fcColor = UIColor(red: 245.0/255, green: 195.0/255, blue: 30.0/255, alpha: 1)
    case "IFR":
        fcColor = UIColor.redColor()
    case "LIFR":
        fcColor = UIColor.redColor()
    default:
        fcColor = UIColor.clearColor()
    }
    
    label.backgroundColor = fcColor
}