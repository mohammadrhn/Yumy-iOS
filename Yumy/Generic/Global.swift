//
//  Global.swift
//  Yumy
//
//  Created by Mohammad Rahmanian on 3/7/17.
//  Copyright © 2017 Yumy. All rights reserved.
//

import UIKit
import MapKit
import SystemConfiguration
import DQAlertView

class Global{
    // MARK: - Static Properties
    
    // Restaurant place properties
    static var placeFiltersArray: [String] = []
    static var placeSearchValue : String = ""
    
    // User related properties
    static var userLocation: CLLocationCoordinate2D?
    
    // Fonts
    static let iranSans14 = UIFont(name: "IRANSans", size: 14.0)
    static let iranSans16 = UIFont(name: "IRANSans", size: 16.0)
    static let iranSans18 = UIFont(name: "IRANSans", size: 18.0)
    static let iranSans20 = UIFont(name: "IRANSans", size: 20.0)
    static let iranSans22 = UIFont(name: "IRANSans", size: 22.0)
    static let iranSans24 = UIFont(name: "IRANSans", size: 24.0)
    
    // Colors
    static let yumyRed = UIColor(red: 196.0/256.0, green: 26.0/256.0, blue: 41.0/256.0, alpha: 1.0)
    
    // Places
    static var places : [Place] = []
    static var filteredPlaces : [Place] = []
    static var nearPlaces : [Place] = []
    static var selectedPlace : Place?
    
    static var internetAvailability = false
    static var isNearMeActivated = false
    
    // MARK: - Static methods
    
    static func createPlaces(parsedData: [Any]){
        places.removeAll()
        for data in parsedData{
            let placeData = data as! [String: Any]
            places.append(createPlaceFromData(data: placeData))
        }
        Global.places.sort{
            let place_location0 = $0.location.coordinate
            let place_location1 = $1.location.coordinate
            let diff_lat_0 = pow(Double(place_location0.latitude) - Double((Global.userLocation?.latitude)!), 2.0)
            let diff_lng_0 = pow(Double(place_location0.longitude) - Double((Global.userLocation?.longitude)!), 2.0)
            
            let diff_lat_1 = pow(Double(place_location1.latitude) - Double((Global.userLocation?.latitude)!), 2.0)
            let diff_lng_1 = pow(Double(place_location1.longitude) - Double((Global.userLocation?.longitude)!), 2.0)
            
            if((diff_lat_0 + diff_lng_0) < (diff_lat_1 + diff_lng_1)){
                return true
            }
            return false
        }
        if(places.isEmpty){
            nearPlaces = []
        } else {
            nearPlaces = Array(places[0..<20])
        }
    }
    
    static func createSamplePlaces(callback: @escaping () -> Void){
        /*let place1 = Place.init(name: "مکان شماره ۱", address: "مکان آباد جنوبی - جنب مکان کناری - مکان کده ۲", phoneNumber: "۰۷۱۳۱۲۳۴۵۶۷", type: "FF", lat: 29.68137, lng: 52.45635)!
        
        let place2 = Place.init(name: "مکان شماره ۲", address: "۱مکان آباد جنوبی - جنب مکان کناری - مکان کده ۲", phoneNumber: "۰۷۱۳۹۸۷۶۵۴۳", type: "CS", lat: 29.679947, lng: 52.458794)!
        
        let place3 = Place.init(name: "مکان شماره ۳", address: "مکان آباد جنوبی - جنب مکان کناری - مکان کده ۲۲", phoneNumber: "۰۹۳۷۴۱۶۲۲۱۰", type: "Rst", lat: 29.683125, lng: 52.465827)!
 
        places.append(place1)
        places.append(place2)
        places.append(place3)
        */
        callback()
    }
    
    static func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    static func isLocationServiceAvailable() -> Bool{
        var status = false
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied:
                status = false
            case .authorizedAlways, .authorizedWhenInUse:
                status = true
            }
        } else {
            status = false
        }
        return status
    }
    
    // MARK: - message methods
    
    static func errorMessage(_ text: String, callback: @escaping () -> (Void))
    {
        DispatchQueue.main.async {
            let alert = DQAlertView.init(title: "خطا", message: text, cancelButtonTitle: "تایید", otherButtonTitle: nil)
            alert?.titleLabel.font = self.iranSans18
            alert?.messageLabel.font = self.iranSans16
            alert?.cancelButton.titleLabel?.font = self.iranSans16
            alert?.cancelButtonAction = {
                callback();
            }
            alert?.show();
        }
    }
    
    static func askMessage(_ text: String, callback: @escaping () -> (Void))
    {
        DispatchQueue.main.async {
            let alert = DQAlertView.init(title: "یامی", message: text, cancelButtonTitle: "بیخیال", otherButtonTitle: "تلاش دوباره")
            alert?.titleLabel.font = self.iranSans18
            alert?.messageLabel.font = self.iranSans16
            alert?.cancelButton.titleLabel?.font = self.iranSans16
            alert?.otherButton.titleLabel?.font = self.iranSans16
            alert?.otherButton.titleLabel?.textColor = UIColor.red
            alert?.otherButtonAction = {
                callback();
            }
            alert?.show();
        }
    }
    
    // MARK: - Private methods
    
    private static func createPlaceFromData(data: [String: Any]) -> Place{
        guard let place = Place.init(name: data["place_name"] as! String, address: data["place_address"] as! String, phoneNumber: data["place_phonenumber"] as? String, type: data["place_type"] as! String, lat: data["place_coord_x"] as! Double, lng: data["place_coord_y"] as! Double, priceClass: data["price_class"] as! String) else {
            print(data)
            fatalError("incorrect place data from server")
        }
        if data["place_working_time"] != nil{
            place.addWrokingTime(workingTime: data["place_working_time"] as! String)
        }
        return place
    }
    
    


}
