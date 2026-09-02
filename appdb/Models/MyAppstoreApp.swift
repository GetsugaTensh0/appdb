//
//  MyAppStoreApp.swift
//  appdb
//
//  Created by ned on 26/04/2019.
//  Copyright Â© 2019 ned. All rights reserved.
//

import SwiftyJSON
import ObjectMapper

class MyAppStoreApp: Item {

    required init?(map: Map) {
        super.init(map: map)
    }

    override class func type() -> ItemType {
        .myAppstore
    }

    override var id: Int {
        get { super.id }
        set { super.id = newValue }
    }

    var name: String = ""
    var bundleId: String = ""
    var version: String = ""
    var uploadedAt: String = ""
    var size: String = ""
    var apiIdentifier: String = ""
    var link: String = ""

    override func mapping(map: Map) {
        name <- map["name"]
        id <- map["id"]
        bundleId <- map["bundle_id"]
        version <- map["bundle_version"]
        uploadedAt <- map["uploaded_at"]
        size <- map["size"]
        if size.isEmpty, let intSize = map.JSON["size"] as? Int {
            size = String(intSize)
        }
        if size.isEmpty {
            size <- map["size_hr"]
        }
        if let intId = map.JSON["id"] as? Int {
            apiIdentifier = String(intId)
        } else {
            apiIdentifier <- map["id"]
        }
        universalObjectIdentifier <- map["universal_object_identifier"]
        if let ticketInt = map.JSON["installation_ticket"] as? Int {
            installationTicket = String(ticketInt)
        } else {
            installationTicket <- map["installation_ticket"]
        }
        link <- map["link"]

        if universalObjectIdentifier.isEmpty {
            universalObjectIdentifier <- map["uoid"]
        }
        if apiIdentifier.isEmpty {
            apiIdentifier <- map["uoid"]
        }
        if apiIdentifier.isEmpty {
            apiIdentifier = universalObjectIdentifier
        }
        if link.isEmpty {
            link <- map["download_link"]
        }
        if uploadedAt.isEmpty, let intDate = map.JSON["uploaded_at"] as? Int {
            uploadedAt = String(intDate)
        }

        if let int64size = Int64(size) {
            size = Global.humanReadableSize(bytes: int64size)
        }
    }
}
