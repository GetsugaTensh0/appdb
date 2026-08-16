//
//  DeviceStatusItem.swift
//  appdb
//
//  Created by ned on 16/05/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON

struct DeviceStatusItem: Mappable, Matchable {

    init?(map: Map) { }

    var uuid: String = ""
    var added: String = ""
    var params: String = ""
    var acknowledged: String = ""
    var status: String = ""
    var type: String = ""
    var timestamp: String = ""
    var title: String = ""
    var bundleId: String = ""
    var purpose: String = ""
    var statusShort: String = ""
    var statusText: String = ""
    var linkId: String = ""
    var uoid: String = ""
    var manifestUri: String = ""
    var downloadUri: String = ""

    mutating func mapping(map: Map) {
        uuid <- map["uuid"]
        params <- map["params"]
        status <- map["status"]
        type <- map["type"]

        if let addedInt = map.JSON["added"] as? Int {
            added = String(addedInt)
        } else if let addedDouble = map.JSON["added"] as? Double {
            added = String(Int(addedDouble))
        } else {
            added <- map["added"]
        }

        if let ackInt = map.JSON["acknowledged"] as? Int {
            acknowledged = String(ackInt)
        } else if let ackDouble = map.JSON["acknowledged"] as? Double {
            acknowledged = String(Int(ackDouble))
        } else {
            acknowledged <- map["acknowledged"]
        }

        acknowledged = acknowledged.unixToDetailedString
        timestamp = Global.formattedTimeFromNow(from: added.unixToDate)

        var parsed = JSON()
        if let dict = map.JSON["params"] as? [String: Any] {
            parsed = JSON(dict)
        } else if let data = params.data(using: .utf8) {
            parsed = JSON(data)
        }

        title = firstString(in: parsed, keys: ["link_data.title", "title", "name", "app_name"])
        bundleId = firstString(in: parsed, keys: ["link_data.bundle_id", "bundle_id"])
        linkId = firstString(in: parsed, keys: ["link_data.id", "link_data.universal_object_identifier", "universal_object_identifier", "id"])
        uoid = firstString(in: parsed, keys: ["universal_object_identifier", "link_data.universal_object_identifier", "uoid"])
        purpose = firstString(in: parsed, keys: ["purpose"])
        statusShort = firstString(in: parsed, keys: ["sign.status", "status_short", "short_status"])
        statusText = firstString(in: parsed, keys: ["sign.status_text", "status_text", "message", "progress"])
        manifestUri = deepString(in: parsed, keys: ["manifest_uri", "manifest_url", "itms", "install_uri", "plist_uri", "plist_url"])
        downloadUri = deepString(in: parsed, keys: ["download_uri", "download_url", "ipa_uri", "ipa_url"])
        if manifestUri.isEmpty {
            manifestUri = firstURL(in: params, matching: "manifest") ?? firstURL(in: params, matching: ".plist") ?? ""
        }
        if statusText.hasSuffix("\n") { statusText = statusText.trimTrailingWhitespace() }
    }

    private func firstString(in json: JSON, keys: [String]) -> String {
        for key in keys {
            let value = key.split(separator: ".").reduce(json) { current, part in current[String(part)] }.stringValue
            if !value.isEmpty { return value }
        }
        return ""
    }

    private func deepString(in json: JSON, keys: [String]) -> String {
        for key in keys {
            let found = deepSearch(json, key: key)
            if !found.isEmpty { return found }
        }
        return firstString(in: json, keys: keys)
    }

    private func deepSearch(_ json: JSON, key: String) -> String {
        if json.type == .dictionary {
            if !json[key].stringValue.isEmpty { return json[key].stringValue }
            for (_, child) in json.dictionaryValue {
                let found = deepSearch(child, key: key)
                if !found.isEmpty { return found }
            }
        } else if json.type == .array {
            for child in json.arrayValue {
                let found = deepSearch(child, key: key)
                if !found.isEmpty { return found }
            }
        }
        return ""
    }

    private func firstURL(in text: String, matching token: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"https?://[^\s\"'\\]+"#) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        for match in regex.matches(in: text, range: range) {
            guard let swiftRange = Range(match.range, in: text) else { continue }
            let url = String(text[swiftRange])
            if url.lowercased().contains(token.lowercased()) { return url }
        }
        return nil
    }

    func match(with object: Any) -> Match {
        guard let status = object as? DeviceStatusItem else { return .none }

        if uuid == status.uuid {
            if statusText == status.statusText && timestamp == status.timestamp {
                return .equal
            } else {
                return .change // Same uuid, but not statusText or timestamp
            }
        } else {
            return .none
        }
    }
}
