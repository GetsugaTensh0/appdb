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

    init() { }

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

        applyTimestamps()
        applyParams(JSON(map.JSON))
    }

    static func parse(_ json: JSON) -> DeviceStatusItem {
        var item = DeviceStatusItem()
        item.uuid = json["uuid"].stringValue
        item.status = json["status"].stringValue
        item.type = json["type"].stringValue
        item.added = stringValue(json["added"])
        item.acknowledged = stringValue(json["acknowledged"])
        if json["params"].type == .string {
            item.params = json["params"].stringValue
        } else if json["params"].type == .dictionary || json["params"].type == .array {
            item.params = json["params"].rawString() ?? ""
        }
        item.applyTimestamps()
        item.applyParams(json)
        return item
    }

    private mutating func applyTimestamps() {
        acknowledged = acknowledged.unixToDetailedString
        timestamp = Global.formattedTimeFromNow(from: added.unixToDate)
    }

    private mutating func applyParams(_ root: JSON) {
        var parsed = decodeParams(root["params"])
        if parsed.type == .null || (parsed.type == .dictionary && parsed.dictionaryValue.isEmpty) {
            parsed = decodeParams(JSON(params))
        }

        title = firstString(in: parsed, keys: ["link_data.title", "title", "name", "app_name"])
        bundleId = firstString(in: parsed, keys: ["link_data.bundle_id", "bundle_id"])
        linkId = firstString(in: parsed, keys: ["link_data.id", "link_data.universal_object_identifier", "universal_object_identifier", "id"])
        uoid = firstString(in: parsed, keys: ["universal_object_identifier", "link_data.universal_object_identifier", "uoid"])
        purpose = firstString(in: parsed, keys: ["purpose"])
        statusShort = firstString(in: parsed, keys: ["sign.status", "status_short", "short_status"])
        statusText = firstString(in: parsed, keys: ["sign.status_text", "status_text", "message", "progress"])
        manifestUri = firstNonEmpty([
            deepString(in: parsed, keys: ["manifest_uri", "manifest_url", "manifestUri", "itms", "itms_services", "itms-services", "install_uri", "plist_uri", "plist_url", "manifest"]),
            deepString(in: root, keys: ["manifest_uri", "manifest_url", "itms", "install_uri", "plist_uri"])
        ])
        downloadUri = firstNonEmpty([
            deepString(in: parsed, keys: ["download_uri", "download_url", "ipa_uri", "ipa_url"]),
            deepString(in: root, keys: ["download_uri", "download_url"])
        ])
        if manifestUri.isEmpty {
            manifestUri = firstURL(in: params, matching: "manifest")
                ?? firstURL(in: params, matching: ".plist")
                ?? firstURL(in: params, matching: "itms")
                ?? firstURL(in: statusText, matching: "manifest")
                ?? firstURL(in: statusText, matching: ".plist")
                ?? ""
        }
        if statusText.hasSuffix("\n") { statusText = statusText.trimTrailingWhitespace() }
    }

    var isFailed: Bool {
        let value = status.lowercased()
        return value.contains("fail") || statusShort.lowercased().contains("fail")
    }

    var isReadyToInstall: Bool {
        !manifestUri.isEmpty || ["ok", "done", "success"].contains(status.lowercased())
    }

    private func decodeParams(_ json: JSON) -> JSON {
        if json.type == .dictionary { return unwrapJSON(json) }
        if json.type == .array { return json }
        let text = json.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let data = text.data(using: .utf8) else { return json }
        let decoded = JSON(data)
        if decoded.type == .string {
            return decodeParams(decoded)
        }
        return unwrapJSON(decoded)
    }

    private func unwrapJSON(_ json: JSON) -> JSON {
        if json.type == .dictionary, json["params"].exists() {
            let nested = json["params"]
            if nested.type == .dictionary { return nested }
            if nested.type == .string { return decodeParams(nested) }
        }
        return json
    }

    private func firstNonEmpty(_ values: [String]) -> String {
        values.first { !$0.isEmpty } ?? ""
    }

    private static func stringValue(_ json: JSON) -> String {
        if !json.stringValue.isEmpty { return json.stringValue }
        if json.int != nil { return String(json.intValue) }
        if json.double != nil { return String(Int(json.doubleValue)) }
        return ""
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
        guard let regex = try? NSRegularExpression(pattern: #"https?://[^\s\"'\\<>]+"#) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        for match in regex.matches(in: text, range: range) {
            guard let swiftRange = Range(match.range, in: text) else { continue }
            let url = String(text[swiftRange]).trimmingCharacters(in: CharacterSet(charactersIn: ".,);"))
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
                return .change
            }
        } else {
            return .none
        }
    }
}
