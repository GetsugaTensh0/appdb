//
//  Promotion.swift
//  appdb
//
//  Created by ned on 26/01/2017.
//  Copyright © 2017 ned. All rights reserved.
//

import ObjectMapper

struct Promotion: Mappable {

    init?(map: Map) { }

    var id: Int = 0
    var lead: String = ""
    var type: String = ""
    var trackid: Int = 0
    var uoid: String = ""
    var name: String = ""
    var image: String = ""

    mutating func mapping(map: Map) {
        id <- map["id"]
        lead <- map["lead"]
        type <- map["type"]
        trackid <- map["trackid"]
        name <- map["name"]
        image <- map["image"]
        uoid <- map["universal_object_identifier"]
        if image.isEmpty { image <- map["icon_uri"] }
        if uoid.isEmpty { uoid <- map["uoid"] }
        if trackid == 0, let parsed = Int(uoid.prefix(8), radix: 16) {
            trackid = abs(parsed)
        }
    }
}
