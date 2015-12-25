//
//  Airport.swift
//  QuickWX
//
//  Created by Alexander on 11/19/15.
//  Copyright © 2015 Alexander. All rights reserved.
//

import Foundation
import CoreLocation

class AirportDesc: NSObject, NSCoding
{
    var Location: CLLocation
    var Code: String
    var Name: String
    
    func encodeWithCoder(aCoder: NSCoder){
        aCoder.encodeObject(Location, forKey: "Location")
        aCoder.encodeObject(Code, forKey: "Code")
        aCoder.encodeObject(Name, forKey: "Name")
    }
    
    required init(coder aDecoder: NSCoder){
        self.Location = aDecoder.decodeObjectForKey("Location") as! CLLocation
        self.Code = aDecoder.decodeObjectForKey("Code") as! String
        self.Name = aDecoder.decodeObjectForKey("Name") as! String
        super.init()
    }

    
    convenience init(code: String, name: String,
        latDegreesStr: String, latMinutesStr: String, latSecondsStr: String,
        lonDegreesStr: String, lonMinutesStr: String, lonSecondsStr: String)
    {
        let latDegrees = Double(latDegreesStr)
        let latMinutes = Double(latMinutesStr)
        var idx = latSecondsStr.endIndex.advancedBy(-1)
        let latSeconds = Double(latSecondsStr.substringToIndex(idx))
        let latDir = CompassPoint(dir: latSecondsStr.substringFromIndex(idx))
        
        let lonDegrees = Double(lonDegreesStr)
        let lonMinutes = Double(lonMinutesStr)
        idx = lonSecondsStr.endIndex.advancedBy(-1)
        let lonSeconds = Double(lonSecondsStr.substringToIndex(idx))
        let lonDir = CompassPoint(dir: lonSecondsStr.substringFromIndex(idx))
        
        self.init(code: code, name: name,
                  latDegrees: latDegrees!, latMinutes: latMinutes!, latSeconds: latSeconds!, latDir: latDir!,
                  lonDegrees: lonDegrees!, lonMinutes: lonMinutes!, lonSeconds: lonSeconds!, lonDir: lonDir!)
    }
    
    convenience init(code: String, name: String,
                     latDegrees: Double, latMinutes: Double, latSeconds: Double, latDir: CompassPoint,
                     lonDegrees: Double, lonMinutes: Double, lonSeconds: Double, lonDir: CompassPoint)
    {
        var latitude  = latDegrees + latMinutes/60 + latSeconds/3600
        var longitude = lonDegrees + lonMinutes/60 + lonSeconds/3600
        
        if latDir == .South {
            latitude = -latitude
        }
        
        if lonDir == .West {
            longitude = -longitude
        }
        
        self.init(code: code, name: name, latitude: latitude, longitude: longitude)
    }
    
    init(code: String, name: String, latitude: Double, longitude: Double)
    {
        Location = CLLocation(latitude: latitude, longitude: longitude)
        Code = code
        Name = name
    }
}

class Airport
{
    typealias CallbackMETAR = (String) -> Void
    typealias CallbackTAF = (TAF) -> Void
    var desc: AirportDesc
    var Code: String { get { return desc.Code } }
    var Name: String { get { return desc.Name } }
    var Location: CLLocation { get { return desc.Location } }
    var hasRecentMETAR: Bool
    var hasRecentTAF: Bool
    var callbackMETAR: CallbackMETAR?
    var callbackTAF: CallbackTAF?
    var metar: METAR?
    var taf: TAF?
    var queryIsInProgress: Bool
    var distance: Double
    var isFavorite: Bool {
        get {
            let favorites = loadFavorites()
            
            for i in 0..<favorites.count {
                if favorites[i].Code == self.Code {
                    return true
                }
            }
            
            return false
        }
    }
    
    init(description: AirportDesc)
    {
        desc = description
        hasRecentMETAR = false
        hasRecentTAF = false
        queryIsInProgress = false
        distance = 0
    }
    
    func getMETAR(callback: (String) -> Void, hoursBeforeNow: Int)
    {
        objc_sync_enter(self)
        
        if queryIsInProgress {
            objc_sync_exit(self)
            return
        }
        
        self.callbackMETAR = callback
        let strRequest = "https://www.aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=K" + Code + "&hoursBeforeNow=" + String(hoursBeforeNow)
        let url = NSURL(string: strRequest)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url!, completionHandler: sessionHandlerMETAR)
        task.resume()
        
        queryIsInProgress = true
        objc_sync_exit(self)
    }
    
    func getTAF(code: String, callback: (TAF) -> Void)
    {
        objc_sync_enter(self)
        
        if queryIsInProgress {
            objc_sync_exit(self)
            return
        }
        
        self.callbackTAF = callback
        let strRequest = "https://www.aviationweather.gov/adds/dataserver_current/httpparam?dataSource=tafs&requestType=retrieve&format=xml&stationString=K" + code + "&hoursBeforeNow=2"
        let url = NSURL(string: strRequest)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url!, completionHandler: sessionHandlerTAF)
        task.resume()
        
        queryIsInProgress = true
        objc_sync_exit(self)
    }
    
    func sessionHandlerMETAR(data: NSData?, response: NSURLResponse?, error: NSError?)
    {
        processMETAR(data!)
    }
    
    func sessionHandlerTAF(data: NSData?, response: NSURLResponse?, error: NSError?)
    {
        processTAF(data!)
    }
    
    func processMETAR(data: NSData)
    {
        let _ = METARParser(data: data, cb: metarReady)
    }
    
    func processTAF(data: NSData)
    {
        let _ = TAFParser(data: data, cb: tafReady)
    }
    
    func metarReady(metar: METAR)
    {
        self.metar = metar
        hasRecentMETAR = true
        queryIsInProgress = false
        callbackMETAR?(Code)
    }
    
    func tafReady(var taf: TAF)
    {
        hasRecentTAF = true
        queryIsInProgress = false
        
        taf.rawText = taf.rawText.stringByReplacingOccurrencesOfString("FM", withString: "\nFM")
        
        //taf.rawText.insert("\n", atIndex: <#T##Index#>)
        
        callbackTAF?(taf)
    }
}

class METARParser: NSObject, NSXMLParserDelegate
{
    typealias Callback = (METAR) -> Void
    var parser: NSXMLParser
    var currentString: String?
    var metar: METAR
    var callback: Callback
    
    init(data: NSData, cb: Callback)
    {
        parser = NSXMLParser(data: data)
        callback = cb
        metar = METAR()
    
        super.init()
        parser.delegate = self
        parser.parse()
    }
    
    func parser(parser: NSXMLParser,
        didStartElement elementName: String,
        namespaceURI nURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String])
    {
        currentString = ""
        if elementName == "sky_condition" && metar.skyCover != "BKN" && metar.skyCover != "OVC" {
            metar.skyCover = attributeDict["sky_cover"]!
            if metar.skyCover == "BKN" || metar.skyCover == "OVC" {
                metar.cloudBaseFtAGL = Int(attributeDict["cloud_base_ft_agl"]!)!
            }
        }
    }
    
    func parser(parser: NSXMLParser,
        foundCharacters string: String)
    {
        currentString = string
    }
    
    func parser(parser: NSXMLParser,
        didEndElement elementName: String,
        namespaceURI nURI: String?,
        qualifiedName qName: String?)
    {
        if elementName == "raw_text" && metar.rawText.isEmpty {
            metar.rawText = currentString!
        } else if elementName == "vert_vis_ft" {
            metar.verticalVisFtAGL = Int(currentString!)!
        } else if elementName == "visibility_statute_mi" {
            metar.visibilitySM = Double(currentString!)!
        } else if elementName == "flight_category" && metar.flightCategory.isEmpty {
            metar.flightCategory = currentString!
        }
    }

    func parserDidEndDocument(parser: NSXMLParser)
    {
        callback(metar)
    }
}

class TAFParser: NSObject, NSXMLParserDelegate
{
    typealias Callback = (TAF) -> Void
    var parser: NSXMLParser
    var currentString: String?
    var taf: TAF
    var callback: Callback
    
    init(data: NSData, cb: Callback)
    {
        parser = NSXMLParser(data: data)
        callback = cb
        taf = TAF()
        
        super.init()
        parser.delegate = self
        parser.parse()
    }
    
    func parser(parser: NSXMLParser,
        foundCharacters string: String)
    {
        currentString = string
    }
    
    func parser(parser: NSXMLParser,
        didEndElement elementName: String,
        namespaceURI nURI: String?,
        qualifiedName qName: String?)
    {
        if elementName == "raw_text" && taf.rawText.isEmpty {
            taf.rawText = currentString!
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser)
    {
        callback(taf)
    }
}

struct METAR
{
    var flightCategory: String
    var rawText: String
    var skyCover: String
    var cloudBaseFtAGL: Int
    var verticalVisFtAGL: Int
    var visibilitySM: Double
    
    init()
    {
        flightCategory = ""
        rawText = ""
        skyCover = ""
        visibilitySM = 0
        cloudBaseFtAGL = 99999
        verticalVisFtAGL = 99999
    }
}

struct TAF
{
    var rawText: String
    
    init()
    {
        rawText = ""
    }
}

func getNearestAirports(airportsDesc: [AirportDesc], location: CLLocation, distanceNM: Double) -> [(Airport)]
{
    var airportsList = [Airport]()
    
    for i in 0..<airportsDesc.count {
        let distance = location.distanceFromLocation(airportsDesc[i].Location) / MetersInNM
        if distance < distanceNM {
            var airport = Airport(description: airportsDesc[i])
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