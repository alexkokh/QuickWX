//
//  AirportTableViewCell.swift
//  QuickWX
//
//  Created by Alexander on 11/21/15.
//  Copyright © 2015 Alexander. All rights reserved.
//

import UIKit

class AirportTableViewCell: UITableViewCell {

    var airport: Airport?
    var labelText = "Sample text"
    var hoursBeforeNow = 1
    @IBOutlet weak var AirportCodeLabel: UILabel!
    @IBOutlet weak var AirportNameLabel: UILabel!
    @IBOutlet weak var AirportDistLabel: UILabel!
    @IBOutlet weak var AirportMETARTextView: UITextView!
    @IBOutlet weak var AirportFlightCategoryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        AirportMETARTextView.textContainer.lineFragmentPadding = 0
        AirportMETARTextView.textContainerInset = UIEdgeInsetsZero
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func cellCallback(code: String)
    {
        if(airport?.metar?.rawText != "" || hoursBeforeNow == MaxHoursBeforeNow) {
            dispatch_async(dispatch_get_main_queue()) {
                self.displayMETAR()
            }
        } else {
            hoursBeforeNow++
            airport?.getMETAR(cellCallback, hoursBeforeNow: hoursBeforeNow)
        }
    }
    
    func setup(airport: Airport)
    {
        self.airport = airport
        AirportCodeLabel.text = airport.Code
        AirportNameLabel.text = airport.Name
        
        if(airport.distance != 0) {
            AirportDistLabel.text = String(format: "%.1f NM", airport.distance)
        } else {
            AirportDistLabel.text = ""
        }
        
        AirportFlightCategoryLabel.backgroundColor = UIColor.clearColor()
        AirportFlightCategoryLabel.text = airport.metar?.flightCategory
        
        if !airport.hasRecentMETAR {
            airport.getMETAR(cellCallback, hoursBeforeNow: hoursBeforeNow)
            AirportMETARTextView.text = "Loading METAR..."
        } else {
            displayMETAR()
        }
    }
    
    func displayMETAR()
    {
        let rawText = airport!.metar?.rawText
        
        if rawText != nil && rawText != "" {
            let textView = AirportMETARTextView
            textView.textContainer.lineFragmentPadding = 0
            textView.textContainerInset = UIEdgeInsetsZero
            textView.text = rawText
            
            setFlightCategoty(AirportFlightCategoryLabel, flightCategory: (self.airport!.metar?.flightCategory)!)
        } else {
            AirportMETARTextView.text = "No WX"
        }
    }
}
