//
//  API+Search.swift
//  appdb
//
//  Created by ned on 11/01/2017.
//  Copyright © 2017 ned. All rights reserved.
//

import Alamofire
import SwiftyJSON
import ObjectMapper
import Foundation

extension API {
    static func isUniversalObjectIdentifier(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count == 40 && trimmed.allSatisfy { $0.isHexDigit }
    }

    static func isRealInstallationTicket(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "0" || trimmed == "1" { return false }
        return trimmed.count >= 16
    }

    static func strippedAPIMessage(_ raw: String) -> String {
        let text = raw.decoded.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? raw : text
    }

    static func v17ContentType(for type: ItemType) -> String? {
        switch type {
        case .ios:
            // official_app is only ~20 titles published on appdb itself.
            // The searchable iOS catalog lives in user_app.
            return "user_app"
        case .cydia:
            return "repo_app"
        case .books:
            return nil
        default:
            return "user_app"
        }
    }

    static func itemType(fromV17 type: String) -> ItemType {
        let value = type.lowercased()
        if value.contains("book") { return .books }
        if value.contains("user") || value.contains("custom") || value.contains("enhancement") || value.contains("cydia") || value.contains("repo") {
            return .cydia
        }
        return .ios
    }

    static func uoid(from entry: JSON) -> String {
        let keys = ["universal_object_identifier", "uoid", "identifier"]
        for key in keys {
            let value = entry[key].stringValue
            if !value.isEmpty { return value }
        }
        return ""
    }

    static func legacyId(from entry: JSON) -> Int {
        if entry["id"].intValue != 0 { return entry["id"].intValue }
        let identifier = uoid(from: entry)
        if identifier.count >= 8, let parsed = Int(String(identifier.prefix(8)), radix: 16) {
            return abs(parsed)
        }
        return abs(identifier.hashValue)
    }

    static func formattedPrice(from entry: JSON) -> String {
        let cents = entry["price_cents_eur"].intValue
        if cents <= 0 { return "0.00" }
        return String(format: "%.2f", Double(cents) / 100.0)
    }

    static func formattedTimestamp(_ raw: String) -> String {
        guard let interval = TimeInterval(raw), interval > 0 else { return raw }
        let date = Date(timeIntervalSince1970: interval)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func screenshotsJSONString(from entry: JSON) -> String {
        var iphone: [[String: String]] = []
        var ipad: [[String: String]] = []

        func append(_ value: JSON, to bucket: inout [[String: String]]) {
            if let list = value.array {
                for item in list {
                    let src = item.stringValue.isEmpty ? item["src"].stringValue : item.stringValue
                    if !src.isEmpty { bucket.append(["src": src]) }
                }
            } else if !value.stringValue.isEmpty {
                bucket.append(["src": value.stringValue])
            }
        }

        let byOs = entry["screenshots_uris_by_os_type"]
        if byOs.exists() {
            append(byOs["ios"], to: &iphone)
            append(byOs["universal"], to: &iphone)
            append(byOs["ipados"], to: &ipad)
        }

        let encoded: [String: Any] = ["iphone": iphone, "ipad": ipad]
        guard let data = try? JSONSerialization.data(withJSONObject: encoded),
              let text = String(data: data, encoding: .utf8) else {
            return "{\"iphone\":[],\"ipad\":[]}"
        }
        return text
    }

    static func mapV17EntryToLegacy(_ entry: JSON, requestedType: ItemType) -> [String: Any] {
        let identifier = uoid(from: entry)
        let seller = entry["developer_name"].stringValue
        let genreId = entry["genre_id"].intValue
        let genreName = entry["genre_name"].stringValue
        let minIos = entry["min_ios_version"].stringValue
        let updatedRaw = entry["updated_at"].stringValue.isEmpty ? (entry["edited_at"].stringValue.isEmpty ? entry["created_at"].stringValue : entry["edited_at"].stringValue) : entry["updated_at"].stringValue
        let updated = formattedTimestamp(updatedRaw)
        let description = entry["description"].stringValue.isEmpty ? entry["lead"].stringValue : entry["description"].stringValue
        let lastParseItunes: [String: Any] = [
            "seller": seller,
            "publisher": seller.isEmpty ? "" : "© \(seller)",
            "published": updated,
            "requirements": minIos.isEmpty ? "" : "iOS \(minIos)+",
            "languages": "",
            "size": entry["size_hr"].stringValue,
            "genre": ["name": genreName, "id": "\(genreId)"],
            "ratings": ["count": 0, "stars": 0]
        ]

        let id = legacyId(from: entry)
        return [
            "id": id,
            "trackid": id,
            "name": entry["name"].stringValue,
            "image": entry["icon_uri"].stringValue.isEmpty ? entry["image"].stringValue : entry["icon_uri"].stringValue,
            "bundle_id": entry["bundle_id"].stringValue,
            "version": entry["version"].stringValue,
            "price": formattedPrice(from: entry),
            "added": updated,
            "genre_id": genreId,
            "artist_id": 0,
            "pname": seller,
            "description": description,
            "whatsnew": entry["whatsnew"].stringValue,
            "screenshots": screenshotsJSONString(from: entry),
            "last_parse_itunes": (try? JSONSerialization.data(withJSONObject: lastParseItunes)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}",
            "type": requestedType.rawValue,
            "updateable": 0,
            "whatsnew_text": entry["whatsnew"].stringValue,
            "universal_object_identifier": identifier,
            "uoid": identifier,
            "pwebsite": entry["website_uri"].stringValue,
            "psupport": entry["support_uri"].stringValue,
            "installation_ticket": entry["installation_ticket"].stringValue,
            "download_ticket": entry["download_ticket"].stringValue
        ]
    }

    static func searchIndexParameters(type: ItemType, order: Order, price: Price, genre: String, dev: String, q: String, page: Int) -> [String: Any] {
        let pageSize = 25
        var params: [String: Any] = [
            "start": max(0, (page - 1) * pageSize),
            "length": pageSize,
            "lang": languageCode,
            "compatibility": "ios"
        ]
        let query = q.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            params["name"] = query.lowercased()
        }
        // Named search drops `type` so "youtube" hits user_app + repo_app + official_app.
        // Empty browse keeps a type so Featured is not a random mix.
        if query.isEmpty, let contentType = v17ContentType(for: type) {
            params["type"] = contentType
        }
        if genre != "0", let genreId = Int(genre) {
            params["genre_id"] = genreId
        }
        if !dev.isEmpty, dev != "0", Int(dev) == nil {
            params["developer_name"] = dev
        }
        switch price {
        case .paid:
            params["cents_min"] = 1
        case .free:
            params["cents_max"] = 0
        case .all:
            break
        }
        _ = order
        return params
    }

    static func fetchGatewayObject(identifier: String, internalId: String = "", success: @escaping (_ json: JSON) -> Void, fail: @escaping (_ error: String) -> Void) {
        let value = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            fail("Couldn't find content with id %@ in our database".localizedFormat(identifier))
            return
        }
        var parameters: [String: Any] = [
            "universal_object_identifier": value
        ]
        let privateId = internalId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !privateId.isEmpty {
            parameters["id"] = Int(privateId) ?? (privateId as Any)
        }
        let request = post(.getLinks, parameters: parameters)
        quickCheckForErrors(request, completion: { ok, hasError, _ in
            if ok {
                request.responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        success(JSON(value))
                    case .failure(let error):
                        fail(error.localizedDescription)
                    }
                }
            } else {
                fail((hasError ?? "Cannot connect").localized())
            }
        })
    }

    static func itemFromGateway<T: Item>(_ type: T.Type, json: JSON) -> T? {
        let object = json["data"]["object"]
        guard object.exists(), object.type != .null else { return nil }
        var adapted = mapV17EntryToLegacy(object, requestedType: T.type())
        adapted["installation_ticket"] = json["data"]["installation_ticket"].stringValue
        adapted["download_ticket"] = json["data"]["download_ticket"].stringValue
        guard let item = Mapper<T>().map(JSON: adapted) else { return nil }
        item.installationTicket = json["data"]["installation_ticket"].stringValue
        item.downloadTicket = json["data"]["download_ticket"].stringValue
        return item
    }

    static func getItem<T>(type: T.Type, identifier: String, success: @escaping (_ item: T) -> Void, fail: @escaping (_ error: String) -> Void) where T: Item {
        fetchGatewayObject(identifier: identifier, success: { json in
            if let item = itemFromGateway(T.self, json: json) {
                success(item)
            } else {
                fail("Couldn't find content with id %@ in our database".localizedFormat(identifier))
            }
        }, fail: fail)
    }

    static func search <T>(type: T.Type, order: Order = .all, price: Price = .all, genre: String = "0", dev: String = "0", trackid: String = "0", q: String = "", page: Int = 1, success: @escaping (_ items: [T]) -> Void, fail: @escaping (_ error: String) -> Void) where T: Item {
        if trackid != "0" {
            getItem(type: T.self, identifier: trackid, success: { success([$0]) }, fail: fail)
            return
        }

        let params = searchIndexParameters(type: T.type(), order: order, price: price, genre: genre, dev: dev, q: q, page: page)
        let request = post(.search, parameters: params)

        quickCheckForErrors(request, completion: { ok, hasError, _ in
            if ok {
                request.responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        let json = JSON(value)
                        let rawItems = json["data"].arrayValue
                        let adapted: [[String: Any]] = rawItems.map { mapV17EntryToLegacy($0, requestedType: T.type()) }
                        success(Mapper<T>().mapArray(JSONArray: adapted))
                    case .failure(let error):
                        fail(error.localizedDescription)
                    }
                }
            } else {
                fail((hasError ?? "Cannot connect").localized())
            }
        })
    }

    static func fastSearch(type: ItemType, query: String, maxResults: Int = 10, success: @escaping (_ results: [String]) -> Void) {
        var params = searchIndexParameters(type: type, order: .all, price: .all, genre: "0", dev: "0", q: query, page: 1)
        params["length"] = maxResults
        params["start"] = 0
        post(.search, parameters: params)
            .responseJSON { response in
                if let value = try? response.result.get() {
                    let data = JSON(value)["data"]
                    var results: [String] = []
                    let max = min(data.count, maxResults)
                    for i in 0..<max { results.append(data[i]["name"].stringValue) }
                    success(results)
                }
            }
    }

    static func quickCheckForErrors(_ request: DataRequest, completion: @escaping (_ ok: Bool, _ hasError: String?, _ errorCode: String?) -> Void) {
        request.responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if !json["success"].boolValue {
                    if !json["errors"].isEmpty {
                        completion(false, json["errors"][0]["translated"].stringValue, json["errors"][0]["code"].stringValue)
                    } else {
                        completion(false, "Oops! Something went wrong. Please try again later.".localized(), "")
                    }
                } else {
                    completion(true, nil, nil)
                }
            case .failure(let error):
                completion(false, error.localizedDescription, "")
            }
        }
    }

    static func getTrending(type: ItemType, order: Order = .all, maxResults: Int = 8, success: @escaping (_ results: [String]) -> Void) {
        var params = searchIndexParameters(type: type, order: order, price: .all, genre: "0", dev: "0", q: "", page: 1)
        params["length"] = maxResults
        params["start"] = 0
        post(.search, parameters: params)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let data = JSON(value)["data"]
                    var results: [String] = []
                    let max = min(data.count, maxResults)
                    for i in 0..<max { results.append(data[i]["name"].stringValue) }
                    success(results)
                default:
                    break
                }
            }
    }
}
