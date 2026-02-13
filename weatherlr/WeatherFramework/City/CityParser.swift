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

public class CityParser {
    var outputPath:String
    var coordinates = [Int: CLLocationCoordinate2D]()
    var citiesWithRadar = [String: String]()

    var cities = [String:City]()
    let provinces = ["AB","BC","PE","MB","NB","NS","NU","ON","QC","SK","NL","NT","YT"]
    let lang = ["https://meteo.gc.ca/forecast/canada/index_f.html?id=", "https://weather.gc.ca/forecast/canada/index_e.html?id="]
    let weatherUrl1 = "https://meteo.gc.ca/city/pages/"
    let weatherUrl2 = "_metric_f.html"
    let geoCoder = CLGeocoder()
    
    public init(outputPath:String) {
        self.outputPath = outputPath
    }
    
    public func perform() {
        for i in 0..<provinces.count {
            for j in 0..<lang.count {
                print("Parsing " + lang[j] + provinces[i])
                
                if let url = URL(string: lang[j] + provinces[i]) {
                    let content = try! String(contentsOf: url, encoding: .utf8)

                    parse(content)
                } else {
                    print("Erreur loading " + lang[j] + provinces[i])
                }
            }
        }
        
        var cityArray = Array(self.cities.values)
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "taskQueue")
        let dispatchSemaphore = DispatchSemaphore(value: 0)

        dispatchQueue.async {

        for i in 0..<cityArray.count {
            let address = CNMutablePostalAddress()
            address.city = cityArray[i].englishName
            address.state = cityArray[i].province
            address.country = "Canada"

                print("enter")
                dispatchGroup.enter()
                sleep(1)
                self.geoCoder.geocodePostalAddress(address) {placemarks, error in
                    print("Address = \(address)");
                    if let placemark = placemarks?.first {
                        if let coordinate = placemark.location?.coordinate {
                            cityArray[i].latitude = "\(coordinate.latitude)"
                            cityArray[i].longitude = "\(coordinate.longitude)"

                            print(coordinate);
                        }
                    }
                    print("leave")
                    dispatchSemaphore.signal()
                    dispatchGroup.leave()
                }

                dispatchSemaphore.wait()

            if cityArray[i].latitude == "" {
                print("enter again")
                dispatchGroup.enter()
                sleep(1)
                self.geoCoder.geocodePostalAddress(address) {placemarks, error in
                    print("Address = \(address)");
                    if let placemark = placemarks?.first {
                        if let coordinate = placemark.location?.coordinate {
                            cityArray[i].latitude = "\(coordinate.latitude)"
                            cityArray[i].longitude = "\(coordinate.longitude)"

                            print(coordinate);
                        }
                    }
                    print("leave")
                    dispatchSemaphore.signal()
                    dispatchGroup.leave()
                }

                dispatchSemaphore.wait()
            }
        }
        }

        dispatchGroup.notify(queue: dispatchQueue){
            print("geocoder completed")

            for i in 0..<cityArray.count {
                print(cityArray[i].englishName)

                if let coor = self.coordinates[i] {
                    cityArray[i].latitude = "\(coor.latitude)"
                    cityArray[i].longitude = "\(coor.longitude)"
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
            let data = try PropertyListEncoder().encode(cityArray)
            try data.write(to: URL(fileURLWithPath: path))
            print("Done!")
        } catch {
            print("Error saving cities :(")
        }
    }
    
    func parse(_ data:String) {
        let regex = try! NSRegularExpression(pattern: "/city/pages/(\\w*)-(\\w\\d*)_metric_(f|e).html\">(.*?)<", options: [.caseInsensitive])
        let results = regex.matches(in: data, options: [], range: NSRange(data.startIndex..., in: data))
        for i in 0..<results.count {
            let province = String(data[Range(results[i].range(at: 1), in: data)!])
            var cityId = String(data[Range(results[i].range(at: 2), in: data)!])
            let lang = String(data[Range(results[i].range(at: 3), in: data)!])
            let cityName = String(data[Range(results[i].range(at: 4), in: data)!])
            
            cityId = province + "-" + cityId
            
            var city = cities[cityId] ?? City()
            if city.id.isEmpty {
                city.id = cityId
                city.province = province
            }

            if lang == "f" {
                city.frenchName = cityName
            } else {
                city.englishName = cityName
            }

            city.radarId = getRadarId(cityId)
            cities[cityId] = city
        }
    }
    
    func getRadarId(_ cityId:String) -> String {
        //let cityWithRadar = citiesWithRadar[cityId]
        
       // if cityWithRadar == nil {
            let urlStr = weatherUrl1 + cityId + weatherUrl2
            if let url = URL(string: urlStr) {
                let content = try! String(contentsOf: url, encoding: .utf8)
                
                let regex = try! NSRegularExpression(pattern: "\"/radar/index_f.html\\?id=(.*?)\"", options: [.caseInsensitive])
                let results = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))

                if results.count > 0, let range = Range(results[0].range(at: 1), in: content) {
                    let radarId = String(content[range])
                    
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
