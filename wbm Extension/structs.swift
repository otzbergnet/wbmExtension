//
//  structs.swift
//  wbm Extension
//
//  Created by Claus Wolf on 22.11.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//


struct Wayback : Decodable {
    let url : String?
    let archived_snapshots : Archive?
}

struct Archive : Decodable {
    let closest : Closest?
}

struct Closest : Decodable {
    let url : String
    let status : String
    let timestamp : String
    let available : Bool
}

struct WaybackSparkline : Decodable {
    let last_ts : String?
    let first_ts : String?
    let years : [ String : [Int]]?
}

struct Boost5 : Decodable {
    var datum : String
    var saveCount : Int
    var status : String
}
