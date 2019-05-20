//
//  CityParser.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import MapKit
import Contacts

class CityParser {
    var outputPath:String
    var coordinates = [Int: CLLocationCoordinate2D]()
    var citiesWithRadar = [String: String]()

    var cities = [String:City]()
    let provinces = ["AB","BC","PE","MB","NB","NS","NU","ON","QC","SK","NL","NT","YT"]
    let lang = ["https://meteo.gc.ca/forecast/canada/index_f.html?id=", "https://weather.gc.ca/forecast/canada/index_e.html?id="]
    let weatherUrl1 = "https://meteo.gc.ca/city/pages/"
    let weatherUrl2 = "_metric_f.html"
    let geoCoder = CLGeocoder()
    
    init(outputPath:String) {
        self.outputPath = outputPath
    }
    
    func perform() {
        for i in 0..<provinces.count {
            for j in 0..<lang.count {
                print("Parsing " + lang[j] + provinces[i])
                
                if let url = URL(string: lang[j] + provinces[i]) {
                    let content = try! NSString(contentsOf: url, usedEncoding: nil)
                    
                    parse(content as String)
                } else {
                    print("Erreur loading " + lang[j] + provinces[i])
                }
            }
        }
        
        var cityArray = [City]()
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "taskQueue")
        let dispatchSemaphore = DispatchSemaphore(value: 0)
        
        dispatchQueue.async {
        
        for (_, city) in self.cities {
            //print(String(city.id) + "|" + city.province + "|" + city.frenchName + "|" + city.englishName)

            let address = CNMutablePostalAddress()
            address.city = city.englishName
            address.state = city.province
            address.country = "Canada"
            
                //let address = city.englishName + ", " + city.province + ", Canada"
                
                print("enter")
                dispatchGroup.enter()
                sleep(1)
                self.geoCoder.geocodePostalAddress(address) {placemarks, error in
                    print("Address = \(address)");
                    if let placemark = placemarks?.first {
                        if let coordinate = placemark.location?.coordinate {
                            city.latitude = "\(coordinate.latitude)"
                            city.longitude = "\(coordinate.longitude)"
                        
                            print(coordinate);
                        }
                    }
                    print("leave")
                    dispatchSemaphore.signal()
                    dispatchGroup.leave()
                }
            
                dispatchSemaphore.wait()
            
            if city.latitude == "" {
                // try again
                // TODO mettre dans une méthode
                print("enter again")
                dispatchGroup.enter()
                sleep(1)
                self.geoCoder.geocodePostalAddress(address) {placemarks, error in
                    print("Address = \(address)");
                    if let placemark = placemarks?.first {
                        if let coordinate = placemark.location?.coordinate {
                            city.latitude = "\(coordinate.latitude)"
                            city.longitude = "\(coordinate.longitude)"
                            
                            print(coordinate);
                        }
                    }
                    print("leave")
                    dispatchSemaphore.signal()
                    dispatchGroup.leave()
                }
                
                dispatchSemaphore.wait()
            }
            
            cityArray.append(city)
        }
        }
        
        dispatchGroup.notify(queue: dispatchQueue){
            print("geocoder completed")
            
            for i in 0..<cityArray.count {
                let city = cityArray[i]
                print(city.englishName)
                
                if let coor = self.coordinates[i] {
                    city.latitude = "\(coor.latitude)"
                    city.longitude = "\(coor.longitude)"
                }
            }
            
            self.successCallback(cityArray)
        }
    }
    
    func geoCode(cityArray:[City], position:Int, workGroup:DispatchGroup)  {
        let city = cityArray[position]
        let address = city.englishName + ", " + city.province + ", Canada"
        
        geoCoder.geocodeAddressString(address) {placemarks, error in
            print("Address = \(address)");
            if let placemark = placemarks?.first {
                let coordinate = placemark.location?.coordinate
                self.coordinates[position] = coordinate!
                print(coordinate!);
            }
            
            let thePosition = position + 1
            if(thePosition<cityArray.count) {
                workGroup.enter()
                self.geoCode(cityArray: cityArray, position: thePosition, workGroup: workGroup)
            }
            
            workGroup.leave()
        }
    }
    
    func successCallback(_ cityArray:[City]) {
        let path = outputPath + "/cities.plist"
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: cityArray, requiringSecureCoding: false)
            try data.write(to: URL(fileURLWithPath: path))
            print("Done!")
        } catch {
            print("Error saving cities :(")
        }
    }
    
    func parse(_ data:String) {
        let regex = try! NSRegularExpression(pattern: "/city/pages/(\\w*)-(\\w\\d*)_metric_(f|e).html\">(.*?)<", options: [.caseInsensitive])
        let results = regex.matches(in: data, options: [], range: NSMakeRange(0, data.distance(from: data.startIndex, to: data.endIndex)))
        for i in 0..<results.count {
            let province = (data as NSString).substring(with: results[i].range(at: 1))
            var cityId = (data as NSString).substring(with: results[i].range(at: 2))
            let lang = (data as NSString).substring(with: results[i].range(at: 3))
            let cityName = (data as NSString).substring(with: results[i].range(at: 4))
            
            cityId = province + "-" + cityId
            
            let city:City
            if let cityTest = cities[cityId] {
                city = cityTest
            } else {
                city = City()
                city.id = cityId
                city.province = province
                
                cities[cityId] = city
            }
            
            if lang == "f" {
                city.frenchName = cityName
            } else {
                city.englishName = cityName
            }
            
            let radarId = getRadarId(cityId)
            city.radarId = radarId
        }
    }
    
    func getRadarId(_ cityId:String) -> String {
        //let cityWithRadar = citiesWithRadar[cityId]
        
       // if cityWithRadar == nil {
            let urlStr = weatherUrl1 + cityId + weatherUrl2
            if let url = URL(string: urlStr) {
                let content = try! NSString(contentsOf: url, usedEncoding: nil) as String
                
                let regex = try! NSRegularExpression(pattern: "\"/radar/index_f.html\\?id=(.*?)\"", options: [.caseInsensitive])
                let results = regex.matches(in: content, options: [], range: NSMakeRange(0, content.distance(from: content.startIndex, to: content.endIndex)))
                
                if results.count > 0 {
                    let radarId = (content as NSString).substring(with: results[0].range(at: 1))
                    
                    citiesWithRadar[cityId] = radarId
                    return radarId
                }
            }
      //  } else {
       //     return cityWithRadar!
      //  }
        
        return ""
    }
}
