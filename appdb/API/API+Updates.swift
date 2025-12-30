//
//  API+Updates.swift
//  appdb
//
//  Created by ned on 10/11/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import Alamofire
import SwiftyJSON

extension API {

    static func getUpdatesTicket(success: @escaping (_ ticket: String) -> Void, fail: @escaping (_ error: String) -> Void) {
        // get_update_ticket is deprecated in API 1.7. Callers should use getUpdates
        // directly without a ticket.
        fail("Update tickets are not used with API v1.7.")
    }

    static func getUpdates(ticket: String? = nil,
                           success: @escaping (_ items: [UpdateableApp]) -> Void,
                           fail: @escaping (_ error: String, _ code: String) -> Void) {
        var parameters: [String: Any] = ["lang": languageCode]
        if let ticket = ticket, !ticket.isEmpty {
            parameters["t"] = ticket
        }
        let request = AF.request(endpoint + Actions.getUpdates.rawValue, parameters: parameters, headers: headersWithCookie)

        quickCheckForErrors(request, completion: { ok, hasError, errorCode in
            if ok {
                request.responseArray(keyPath: "data") { (response: AFDataResponse<[UpdateableApp]>) in
                    switch response.result {
                    case .success(var items):

                        // Cleanup mismatch versions
                        for item in items {
                            var new = item.versionNew
                            var old = item.versionOld
                            new = new.replacingOccurrences(of: " ", with: "")
                            old = old.replacingOccurrences(of: " ", with: "")
                            if new.hasPrefix("v") { new = String(new.dropFirst()) }
                            if old.hasPrefix("v") { old = String(old.dropFirst()) }
                            if new.compare(old, options: .numeric) != .orderedDescending {
                                debugLog("found mismatch for \(item.name): new: \(new), old: \(old). Removing...")
                                items.remove(at: items.firstIndex(of: item)!)
                            }
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
