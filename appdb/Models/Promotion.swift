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
    var name: String = ""
    var image: String = ""

    mutating func mapping(map: Map) {
        id <- map["id"]
        lead <- map["lead"]
        type <- map["type"]
        trackid <- map["trackid"]
        name <- map["name"]
        image <- map["image"]
        if image.isEmpty { image <- map["icon_uri"] }
        if trackid == 0 { trackid <- map["universal_object_identifier"] }
    }
}
