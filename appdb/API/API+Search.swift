//
//  API+Search.swift
//  appdb
//
//  Created by ned on 11/01/2017.
//  Copyright Â© 2017 ned. All rights reserved.
//

import Alamofire
import SwiftyJSON
import ObjectMapper

extension API {
    private static func legacyId(from entry: JSON) -> Int {
        if entry["id"].intValue != 0 { return entry["id"].intValue }
        let uoid = entry["universal_object_identifier"].stringValue
        if uoid.count >= 8 {
            let prefix = String(uoid.prefix(8))
            return Int(prefix, radix: 16) ?? abs(prefix.hashValue)
        }
        return abs(entry["name"].stringValue.hashValue)
    }

    private static func mapSearchEntryToLegacy(_ entry: JSON, requestedType: ItemType) -> [String: Any] {
        let mappedType: String = {
            let raw = entry["type"].stringValue
            if raw == "official_app" { return "ios" }
            if raw.contains("book") { return "books" }
            if raw.contains("cydia") || raw.contains("enhancement") { return "cydia" }
            return requestedType.rawValue
        }()

        let seller = entry["developer_name"].stringValue
        let genreId = entry["genre_id"].intValue
        let minIos = entry["min_ios_version"].stringValue
        let lastParseItunes: [String: Any] = [
            "seller": seller,
            "publisher": seller,
            "published": "",
            "requirements": minIos.isEmpty ? "" : "iOS \(minIos)+",
            "languages": "",
            "genre": ["name": "", "id": "\(genreId)"],
            "ratings": ["count": 0, "stars": 0]
        ]

        let id = legacyId(from: entry)
        return [
            "id": id,
            "trackid": id,
            "name": entry["name"].stringValue,
            "image": entry["icon_uri"].stringValue,
            "bundle_id": entry["bundle_id"].stringValue.isEmpty ? "uoid.\(id)" : entry["bundle_id"].stringValue,
            "version": entry["version"].stringValue,
            "price": entry["price_cents_eur"].intValue == 0 ? "0.00" : "\(entry["price_cents_eur"].intValue)",
            "added": "",
            "genre_id": genreId,
            "artist_id": 0,
            "pname": seller,
            "description": entry["lead"].stringValue,
            "whatsnew": "",
            "screenshots": "{\"iphone\":[],\"ipad\":[]}",
            "last_parse_itunes": (try? JSONSerialization.data(withJSONObject: lastParseItunes)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}",
            "type": mappedType,
            "updateable": 0,
            "whatsnew_text": "",
            "universal_object_identifier": entry["universal_object_identifier"].stringValue
        ]
    }

    static func search <T>(type: T.Type, order: Order = .all, price: Price = .all, genre: String = "0", dev: String = "0", trackid: String = "0", q: String = "", page: Int = 1, success: @escaping (_ items: [T]) -> Void, fail: @escaping (_ error: String) -> Void) where T: Item {
        var params: [String: Any] = [
            "order": order.rawValue,
            "price": price.rawValue,
            "genre": genre,
            "dev": dev,
            "q": q,
            "start": 25 * (page - 1),
            "length": 25,
            "lang": languageCode
        ]
        if trackid != "0" {
            params["trackid"] = trackid
            params["id"] = trackid
            params["uoid"] = trackid
        }
        let request = AF.request(endpoint + Actions.search.rawValue, parameters: params, headers: headers)

        quickCheckForErrors(request, completion: { ok, hasError, _ in
            if ok {
                request.responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        let json = JSON(value)
                        let adapted: [[String: Any]] = json["data"].arrayValue.map { mapSearchEntryToLegacy($0, requestedType: T.type()) }
                        let items = Mapper<T>().mapArray(JSONArray: adapted)
                        success(items)
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
        AF.request(endpoint + Actions.search.rawValue, parameters: ["order": Order.all.rawValue,
                                         "q": query,
                                         "lang": languageCode,
                                         "length": maxResults,
                                         "start": 0], headers: headers)

            .responseJSON { response in
                if let value = try? response.result.get() {
                    let json = JSON(value)
                    let data = json["data"]
                    var results: [String] = []
                    let max = data.count > maxResults ? maxResults : data.count
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
        AF.request(endpoint + Actions.search.rawValue, parameters: ["order": order.rawValue,
                                         "lang": languageCode,
                                         "length": maxResults,
                                         "start": 0], headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    let data = json["data"]
                    var results: [String] = []
                    let max = data.count > maxResults ? maxResults : data.count
                    for i in 0..<max { results.append(data[i]["name"].stringValue) }
                    success(results)
                default:
                    break
                }
            }
    }
}
