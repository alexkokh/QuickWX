//
//  ViewController.swift
//  QuickWX
//
//  Created by Alexander on 11/19/15.
//  Copyright © 2015 Alexander. All rights reserved.
//

import UIKit
import CoreLocation

class AirportInfoViewController: UIViewController {
    var airport: Airport?
    var airportsDesc: [AirportDesc]?
    var currentNearestAttempt = 0
    var nearestAirports = [Airport]()
    
    @IBAction func FavoritesButtonTapped(sender: AnyObject) {

        if(!airport!.isFavorite) {
            addToFavorites(airport!)
        } else {
            deleteFromFavorites(airport!)
        }
        
        setFavoritesIcon()
    }
    
    @IBOutlet weak var AirportCodeLabel: UILabel!
    @IBOutlet weak var AirportNameLabel: UILabel!
    @IBOutlet weak var AirportDistanceLabel: UILabel!
    @IBOutlet weak var AirportMETARTextView: UITextView!
    @IBOutlet weak var AirportTAFTextView: UITextView!
    @IBOutlet weak var AirportFlightCategoryLabel: UILabel!
    
    func setFavoritesIcon()
    {
        if(airport!.isFavorite) {
            self.navigationItem.rightBarButtonItem?.image = UIImage(named: "FavoritesIconSelected")
        } else {
            self.navigationItem.rightBarButtonItem?.image = UIImage(named: "FavoritesIconDeselected")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        AirportCodeLabel.text = airport?.desc.Code
        AirportNameLabel.text = airport?.desc.Name
        
        if airport?.distance != 0 {
            AirportDistanceLabel.text = String(format: "%.1f NM", (airport?.distance)!)
        } else {
            AirportDistanceLabel.text = ""
        }
        
        AirportMETARTextView.textContainer.lineFragmentPadding = 0
        AirportMETARTextView.textContainerInset = UIEdgeInsetsZero
        
        var metarText: String
        if airport?.metar?.rawText != "" {
            metarText = (airport?.metar?.rawText)!
        } else {
            metarText = "No WX"
        }
        
        AirportMETARTextView.text = metarText
        AirportTAFTextView.textContainer.lineFragmentPadding = 0
        AirportTAFTextView.textContainerInset = UIEdgeInsetsZero
        
        if airport?.hasRecentTAF == false {
            airport!.getTAF(airport!.Code, callback: callbackTAF)
            AirportTAFTextView.text = "Loading TAF..."
        } else {
            AirportTAFTextView.text = airport?.taf?.rawText
        }
        
        setFlightCategoty(AirportFlightCategoryLabel, flightCategory: (self.airport!.metar?.flightCategory)!)
        
        setFavoritesIcon()
    }
    
    func callbackTAF(taf: TAF)
    {
        if(taf.rawText == "") {
            if(nearestAirports.count == 0) {
                nearestAirports = getNearestAirports(airportsDesc!, location: (airport?.Location)!, distanceNM: 50)
                currentNearestAttempt = 1
            }
            
            if(currentNearestAttempt < nearestAirports.count) {
                let nearestCode = nearestAirports[currentNearestAttempt].Code
                airport!.getTAF(nearestCode, callback: callbackTAF)
                currentNearestAttempt += 1
            }
            
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.currentNearestAttempt = 1
            self.airport?.taf = taf
            self.AirportTAFTextView.text = self.airport?.taf?.rawText
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

