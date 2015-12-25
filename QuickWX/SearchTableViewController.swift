//
//  SearchTableViewController.swift
//  QuickWX
//
//  Created by Alexander on 12/21/15.
//  Copyright © 2015 Alexander. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreLocation

class SearchTableViewController: UITableViewController, UISearchBarDelegate {
    @IBOutlet weak var SearchBar: UISearchBar!
    
    var locator: AirportLocator?
    var searchResults = [Airport]()
    let defaultText = "Airport code"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SearchBar.delegate = self
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar)
    {
        SearchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar)
    {
        SearchBar.showsCancelButton = false
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        SearchBar.resignFirstResponder()
        searchAirports(SearchBar.text!)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar)
    {
        SearchBar.showsCancelButton = false
        SearchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar,
        textDidChange searchText: String)
    {
        if searchText == "" {
            searchResults.removeAll()
            tableView.reloadData()
        }
    }
    
    func searchAirports(seachString: String)
    {
        searchResults.removeAll()
        if seachString == defaultText {
            tableView.reloadData()
            return
        }
        
        var code = seachString
        
        if code.hasPrefix("K") && code.characters.count == 4 {
            code = code.substringFromIndex(code.startIndex.advancedBy(1))
        }
        
        for i in 0..<airportDesc.count {
            if airportDesc[i].Code.containsString(code) {
                searchResults.append(Airport(description: airportDesc[i]))
            }
        }
        
        tableView.reloadData()
        locator = AirportLocator()
        locator?.refresh(locatorCallback)
    }
    
    func locatorCallback(location: CLLocation)
    {
        for i in 0..<searchResults.count {
            searchResults[i].distance = location.distanceFromLocation(searchResults[i].desc.Location) / MetersInNM
        }
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AirportTableViewCell", forIndexPath: indexPath) as! AirportTableViewCell
        
        let idx = indexPath.row
        cell.setup(searchResults[idx])
        
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return searchResults.count
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
                airportInfoViewController.airport = searchResults[(index?.row)!]
                airportInfoViewController.airportsDesc = airportDesc
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Search", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
            }
        }
    }
}