//
//  API+Updates.swift
//  appdb
//
//  Created by ned on 10/11/2018.
//  Copyright Â© 2018 ned. All rights reserved.
//

import Alamofire
import SwiftyJSON

extension API {

    static func getUpdates(ticket: String = "", success: @escaping (_ items: [UpdateableApp]) -> Void, fail: @escaping (_ error: String, _ code: String) -> Void) {
        var params: [String: Any] = [:]
        if !ticket.isEmpty { params["t"] = ticket }
        let request = post(.getUpdates, parameters: params)

        quickCheckForErrors(request, completion: { ok, hasError, errorCode in
            if ok {
                request.responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        let json = JSON(value)
                        let payload = json["data"].arrayValue.isEmpty ? json["data"]["items"] : json["data"]
                        var items: [UpdateableApp] = []
                        for entry in payload.arrayValue {
                            if let mapped = UpdateableApp(JSONString: entry.rawString() ?? "") {
                                items.append(mapped)
                            }
                        }

                        items.removeAll { item in
                            var new = item.versionNew.replacingOccurrences(of: " ", with: "")
                            var old = item.versionOld.replacingOccurrences(of: " ", with: "")
                            if new.hasPrefix("v") { new = String(new.dropFirst()) }
                            if old.hasPrefix("v") { old = String(old.dropFirst()) }
                            let mismatch = new.compare(old, options: .numeric) != .orderedDescending
                            if mismatch { debugLog("found mismatch for \(item.name): new: \(new), old: \(old). Removing...") }
                            return mismatch
                        }
                        success(items)
                    case .failure(let error):
                        fail(error.localizedDescription, "")
                    }
                }
            } else {
                fail(hasError ?? "Cannot connect".localized(), errorCode ?? "")
            }
        })
    }
}
