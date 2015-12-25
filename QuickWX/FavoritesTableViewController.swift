//
//  FavoritesTableViewController.swift
//  QuickWX
//
//  Created by Alexander on 12/19/15.
//  Copyright © 2015 Alexander. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreLocation

class FavoritesTableViewController: UITableViewController {
    var locator: AirportLocator?
    var favDescs = [AirportDesc]()
    var favorites = [Airport]()
    
    @IBAction func refreshButtonTapped(sender: AnyObject) {
        for i in 0..<favorites.count {
            favorites[i].hasRecentMETAR = false
            favorites[i].hasRecentTAF = false
        }
        
        tableView.reloadData()
        locator = AirportLocator()
        locator?.refresh(locatorCallback)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func locatorCallback(location: CLLocation)
    {
        for i in 0..<favorites.count {
            favorites[i].distance = location.distanceFromLocation(favorites[i].desc.Location) / MetersInNM
        }

        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        let descs = loadFavorites()
        var same = true
        
        if(descs.count == favDescs.count) {
            for i in 0..<descs.count {
                if descs[i].Code != favDescs[i].Code {
                    same = false
                    break
                }
            }
        } else {
            same = false
        }
        
        if(!same) {
            favorites.removeAll()
            for i in 0..<descs.count {
                favorites.append(Airport(description: descs[i]))
            }
        
            tableView.reloadData()
        }
        
        locator = AirportLocator()
        locator?.refresh(locatorCallback)
        favDescs = descs
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
        return favorites.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AirportTableViewCell", forIndexPath: indexPath) as! AirportTableViewCell
        
        let idx = indexPath.row
        cell.setup(favorites[idx])
        
        return cell
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
                airportInfoViewController.airport = favorites[(index?.row)!]
                airportInfoViewController.airportsDesc = airportDesc
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Favorites", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
            }
        }
    }
}