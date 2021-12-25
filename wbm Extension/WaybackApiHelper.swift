//
//  apiHelper.swift
//  Wayback Extension
//
//  Created by Claus Wolf on 03.10.21.
//  Copyright © 2021 Claus Wolf. All rights reserved.
//

import Foundation

class WaybackApiHelper {
    
    let settings = SettingsHelper()
    var callMemory : [String : Boost5] = [:]
    
    func doWaybackCall(currentURL : String, completion: @escaping (Result<Boost5, Error>) -> ()){

        if(currentURL == ""){
            let error = NSError(domain: "", code: 400, userInfo: ["msg" : "bad request: no url"])
            completion(.failure(error))
            return
        }
        if(!currentURL.contains("http://") && !currentURL.contains("https://")){
            let error = NSError(domain: "", code: 400, userInfo: ["msg" : "bad request: not http or https"])
            completion(.failure(error))
            return
        }
        
        // if the item is present in call memory and the associated apiCall wasn't more than 15 minutes (900 seconds)
        // ago return that memory object and be done
        if (callMemory[currentURL] != nil) {
            if let callMemoryResult = callMemory[currentURL] {
                let currentTimestamp = Int(NSDate().timeIntervalSince1970) - 900
                if(callMemoryResult.apiTimestamp > currentTimestamp){
                    completion(.success(callMemoryResult))
                    return
                }
            }
        }
        
        let jsonUrlString = "https://web.archive.org/__wb/sparkline?url=\(currentURL)&collection=web&output=json"
        guard let url = URL(string: jsonUrlString) else{
            let error = NSError(domain: "", code: 400, userInfo: ["msg" : "bad request: invalid url"])
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("web.archive.org", forHTTPHeaderField: "Referer")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                completion(.failure(error))
                return
            }
            if let data = data {
                if let httpResponse = response as? HTTPURLResponse {
                    if(httpResponse.statusCode == 200){
                        //we need to handle the data here
                        let response = self.handleData(data: data)
                        self.callMemory[currentURL] = response
                        completion(.success(response))
                    }
                    else{
                        let error = NSError(domain: "", code: 404, userInfo: ["msg" : "httpError \(httpResponse.statusCode)"])
                        completion(.failure(error))
                        return
                    }
                }
                
            }
            else{
                // data wasn't there, which is also a type of eror
                let error = NSError(domain: "", code: 400, userInfo: ["msg" : "network error"])
                completion(.failure(error))
                return
            }
            
        }
        
        task.resume()
    }
    
    func handleData(data: Data) -> Boost5{
        //sole purpose is to dispatch the url
        do{
            let archive = try JSONDecoder().decode(WaybackSparkline.self, from: data)
            
            if let closest = archive.last_ts {
                let saveCount = self.getMementoCount(archive: archive)
                let datum = self.convertTimestamp(timestamp: closest)
                let timestamp = Int(NSDate().timeIntervalSince1970)
                let returnObject = Boost5(apiTimestamp: timestamp, datum: datum, saveCount: saveCount, status: "ok")
                return returnObject;
            }
            else {
                let returnObject = Boost5(apiTimestamp: 0, datum: "", saveCount: 0, status: "never")
                return returnObject;
                
            }
        }
        catch let jsonError{
            NSLog("wbm_log json_Error: \(jsonError)")
            print(jsonError)
            let returnObject = Boost5(apiTimestamp: 0, datum: "", saveCount: 0, status: "fail json")
            return returnObject;
        }
    }
    
    func getMementoCount(archive: WaybackSparkline) -> Int{
        var sum = 0
        if let years = archive.years {
            for year in years {
                for value in year.value {
                    sum += value
                }
            }
        }
        return sum;
    }
    
    func convertTimestamp(timestamp: String) -> String{
        let relativeDate = self.settings.getBoolData(key: "relativeTimestamp")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale.current
        if let date = dateFormatter.date(from: timestamp){
            
            if(relativeDate){
                let relativeDateString = self.readableIntervalSinceNow(date: date)
                return relativeDateString
            }
            else{
                let displayFormatter = DateFormatter()
                displayFormatter.locale = Locale.current
                displayFormatter.setLocalizedDateFormatFromTemplate("yyyyMMMddHHmm")
                return displayFormatter.string(from: date)
            }
            
        }
        return "failed to convert date"
    }
    
    func readableIntervalSinceNow(date: Date) -> String {
        
        let timeInterval = date.timeIntervalSinceNow
        
        if (timeInterval > -3600) { // less than 1 hour
            return NSLocalizedString("just now.", comment: "just now")
        }
        else if (timeInterval > -86400) { // less than a day
            let hours = abs(timeInterval / 3600)
            let hourString = String(format: "%.0f", hours)
            if(hourString == "1"){
                return String(format: NSLocalizedString("1 hour ago", comment: "relative timestring one hour ago"), hourString)
            }
            else{
                return String(format: NSLocalizedString("%@ hours ago", comment: "relative timestring xxx hours ago"), hourString)
            }
        }
        else if (timeInterval > (-604800 * 4)) { // less than a months
            let days = abs(timeInterval / 86400)
            let dayString = String(format: "%.0f", days)
            if(dayString == "1"){
                return String(format: NSLocalizedString("1 day ago", comment: "relative timestring one day ago"), dayString)
            }
            else{
                return String(format: NSLocalizedString("%@ days ago", comment: "relative timestring xxx days ago"), dayString)
            }
            
        }
        else if (timeInterval > (-604800 * 4 * 3)) { // less than 3 months
            let weeks = abs(timeInterval / 604800)
            let weekString = String(format: "%.0f", weeks)
            if (weekString == "1"){
                return String(format: NSLocalizedString("1 week ago", comment: "relative timestring one week ago"), weekString)
            }
            else{
                return String(format: NSLocalizedString("%@ weeks ago", comment: "relative timestring xxx weeks ago"), weekString)
            }
            
        }
        else {
            let dateFormatter = DateFormatter()
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMM YYYY")
            dateFormatter.locale = Locale.current
            return "\(dateFormatter.string(from: date))."
        }
        
    }
    
    func formatPoints(from: Int, places: Int = 1) -> String {
        
        let number = Double(from)
        let thousand = number / 1000
        let million = number / 1000000
        let billion = number / 1000000000
        
        if billion >= 1.0 {
            return "\(roundToPlaces(number: billion, places: places))B"
        }
        else if million >= 1.0 {
            return "\(roundToPlaces(number: million, places: places))M"
        }
        else if thousand >= 1.0 {
            return ("\(roundToPlaces(number: thousand, places: places))K")
        }
        else {
            return "\(Int(number))"
        }
    }
    
    func roundToPlaces(number: Double, places:Int) -> String {
        let divisor = pow(10.0, Double(places))
        let rounded = round(number * divisor) / divisor
        let remainder = rounded.truncatingRemainder(dividingBy: 1)
        
        if(remainder > 0){
            return "\(rounded)"
        }
        else {
            let intRounded = Int(rounded)
            return "\(intRounded)"
        }
    }
}
