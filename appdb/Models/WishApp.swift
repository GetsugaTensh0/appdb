//
//  WishApp.swift
//  appdb
//
//  Created by ned on 07/07/2019.
//  Copyright © 2019 ned. All rights reserved.
//

import UIKit
import ObjectMapper
import Localize_Swift

struct WishApp: Mappable {

    init?(map: Map) { }

    var id: Int = 0
    var trackid: Int = 0
    var version: String = ""
    var image: String = ""
    var name: String = ""
    var requestersAmount: String = ""
    var price: String = ""
    var statusString: String = ""
    var status: Status = .new
    var statusChangedAt: String = ""
    var bundleId: String = ""

    enum Status: String {
        case cracking, fulfilled, failed, new

        var prettified: String {
            switch self {
            case .new: return "New".localized()
            case .cracking: return "⚙︎ " + "Processing".localized()
            case .failed: return "𐄂 " + "Failed".localized()
            case .fulfilled: return "✓ " + "Fulfilled".localized()
            }
        }
    }

    mutating func mapping(map: Map) {
        id <- map["id"]
        trackid <- map["trackid"]
        version <- map["version"]
        image <- map["image"]
        if image.isEmpty { image <- map["icon_uri"] }
        name <- map["name"]
        requestersAmount <- map["requesters_amount"]
        if requestersAmount.isEmpty, let intVal = map.JSON["requesters_amount"] as? Int {
            requestersAmount = String(intVal)
        }
        price <- map["price"]
        if price.isEmpty, let intVal = map.JSON["price"] as? Int {
            price = String(intVal)
        }
        statusString <- map["status"]
        statusChangedAt <- map["status_changed_at"]
        if statusChangedAt.isEmpty, let intDate = map.JSON["status_changed_at"] as? Int {
            statusChangedAt = String(intDate)
        }
        bundleId <- map["bundle_id"]

        name = name.decoded

        price = price == "0.00" ? "Free".localized() : price

        status = Status(rawValue: statusString) ?? .new

        let date = statusChangedAt.unixToDate
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: Localize.currentLanguage())
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        statusChangedAt = dateFormatter.string(from: date)
    }
}
