//
//  SettingsHelper.swift
//  wbm
//
//  Created by Claus Wolf on 17.11.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Foundation

class SettingsHelper {

    var defaults: UserDefaults

    init(){
        self.defaults = UserDefaults(suiteName: "J3PNNM2UXC.wbm")!
    }
    
    func getStringData(key : String) -> String{
        let data : String = self.defaults.string(forKey: key) ?? ""
        return data
    }
    
    func getIntData(key : String) -> Int{
        let data : Int = self.defaults.integer(forKey: key)
        return data
    }
    
    func setStringData(key : String, data: String){
        self.defaults.set(data, forKey: key)
        self.defaults.synchronize()
    }
    
    func setIntData(key: String, data: Int){
        self.defaults.set(data, forKey: key)
        self.defaults.synchronize()
    }

    func setBoolData(key: String, data: Bool){
        self.defaults.set(data, forKey: key)
        self.defaults.synchronize()
    }
    
    func getBoolData(key: String) -> Bool {
        return self.defaults.bool(forKey: key)
    }
    
}
