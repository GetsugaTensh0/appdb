//
//  AltStoreApp.swift
//  appdb
//
//  Created by stev3fvcks on 17.03.23.
//  Copyright © 2023 stev3fvcks. All rights reserved.
//

import ObjectMapper
import Localize_Swift
import UIKit

class AltStoreApp: Item {

    required init?(map: Map) {
        super.init(map: map)
    }

    override var id: Int {
        get { super.id }
        set { super.id = newValue }
    }

    override class func type() -> ItemType {
        .altstore
    }

    static func == (lhs: AltStoreApp, rhs: AltStoreApp) -> Bool {
        lhs.id == rhs.id && lhs.version == rhs.version
    }

    var name: String = ""
    var image: String = ""

    // General
    var developer: String = ""

    // Text
    var description_: String = ""
    var whatsnew: String = ""

    // Information
    var bundleId: String = ""
    var version: String = ""
    var price: String = ""
    var updated: String = ""

    // Beta
    var beta = false

    // Screenshots
    var screenshotURLs: [String] = []
    var screenshots = [Screenshot]()

    var subtitle: String = ""
    var downloadURL: String = ""
    var size: Int64 = 0
    var formattedSize: String = ""
    var tintColor: UIColor = .white
    var tintColorHex: String = ""

    override func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        subtitle <- map["subtitle"]
        version <- map["version"]
        developer <- map["developerName"]
        bundleId <- map["bundleIdentifier"]
        downloadURL <- map["downloadURL"]
        image <- map["iconURL"]
        description_ <- map["localizedDescription"]
        beta <- map["beta"]
        screenshotURLs <- map["screenshotURLs"]
        size <- map["size"]
        tintColorHex <- map["tintColor"]
        updated <- map["versionDate"]
        whatsnew <- map["versionDescription"]

        // contents_uri JSON uses versions[0] for per-version fields
        if let versions = map.JSON["versions"] as? [[String: Any]], let latest = versions.first {
            if version.isEmpty, let v = latest["version"] as? String { version = v }
            if downloadURL.isEmpty, let dl = latest["downloadURL"] as? String { downloadURL = dl }
            if size == 0, let s = latest["size"] as? Int64 { size = s }
            if size == 0, let s = latest["size"] as? Int { size = Int64(s) }
            if updated.isEmpty, let d = latest["date"] as? String { updated = d }
            if whatsnew.isEmpty, let wn = latest["localizedDescription"] as? String { whatsnew = wn }
            if let minOS = latest["minOSVersion"] as? String, !minOS.isEmpty {
                // Store for display
            }
        }

        name = name.decoded
        subtitle = subtitle.decoded
        description_ = description_.decoded
        whatsnew = whatsnew.decoded

        formattedSize = Global.humanReadableSize(bytes: size)

        tintColor = .init(rgba: tintColorHex)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: Localize.currentLanguage())
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        if updated.contains("T") || updated.contains("-") {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let parsed = iso.date(from: updated) ?? {
                iso.formatOptions = [.withInternetDateTime]
                return iso.date(from: updated)
            }()
            if let parsed = parsed {
                updated = dateFormatter.string(from: parsed)
            }
        } else {
            let date = updated.unixToDate
            updated = dateFormatter.string(from: date)
        }

        if !screenshotURLs.isEmpty {
            screenshots = screenshotURLs.map({ screenshotURL in
                Screenshot(src: screenshotURL, type: "iphone")
            })
        }
    }
}
