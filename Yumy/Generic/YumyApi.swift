//
//  YumyApi.swift
//  Yumy
//
//  Created by Mohammad Rahmanian on 3/7/17.
//  Copyright © 2017 Yumy. All rights reserved.
//

import UIKit

class YumyAPI{
    // MARK: - Properties
    private static let endPoint: String = "https://yumy.ir/APIv1"
    
    // API URLs
    static let searchURL = "\(endPoint)/search/"
    static var loadPlacesURL = "\(endPoint)/filterplaces/"
    
    //MARK: - Static Methods
    
    static func loadPlaces(callback: @escaping () -> Void){
        let url = URL(string: self.filterPlacesURI())!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let postString = ""
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            let parsedData = try? JSONSerialization.jsonObject(with: data, options: []) as! [Any]
            Global.createPlaces(parsedData: parsedData!)
            callback()
        }
        task.resume()
    }
    
    static func filterPlacesURI() -> String{
        var uri = self.loadPlacesURL + "?"
        for filterElement in Global.placeFiltersArray{
            uri = uri + "\(filterElement)=1&"
        }
        
        return uri
    }
}
