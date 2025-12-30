//
//  API+Subscriptions.swift
//  appdb
//
//  Created for API 1.7 subscription handling.
//

import Alamofire
import SwiftyJSON

extension API {

    /// Refreshes subscription-related preferences using API v1.7 /get_subscriptions/.
    /// This is a best-effort helper: failures are ignored by callers in most cases.
    static func refreshSubscriptions(success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        guard Preferences.deviceIsLinked else {
            fail("Device is not linked")
            return
        }

        var parameters: [String: Any] = [
            "lang": languageCode
        ]

        // `lt` is required by the 1.7 spec; also sent via cookie.
        let token = Preferences.linkToken
        if !token.isEmpty {
            parameters["lt"] = token
        }

        AF.request(endpoint + "get_subscriptions/", method: .post, parameters: parameters, headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        let message = json["errors"].arrayValue.first?["translated"].stringValue ?? "Unknown error"
                        fail(message)
                        return
                    }

                    let subs = json["data"].arrayValue
                    guard !subs.isEmpty else {
                        // No active subscriptions
                        Preferences.set(.isPlus, to: false)
                        Preferences.set(.plusUntil, to: "")
                        success()
                        return
                    }

                    // Pick subscription with the furthest expiration date
                    let now = Date().timeIntervalSince1970
                    let best = subs.max(by: { lhs, rhs in
                        lhs["expires_at"].doubleValue < rhs["expires_at"].doubleValue
                    }) ?? subs[0]

                    let expiresAt = best["expires_at"].doubleValue
                    let status = best["status"].stringValue // e.g. active, expired
                    let provider = best["provider"].stringValue
                    let supportUri = best["support_uri"].stringValue

                    let isActive = status == "active" && expiresAt > now

                    Preferences.set(.isPlus, to: isActive)
                    if expiresAt > 0 {
                        Preferences.set(.plusUntil, to: String(Int(expiresAt)))
                    }
                    if !provider.isEmpty {
                        Preferences.set(.plusProvider, to: provider)
                    }
                    if !supportUri.isEmpty {
                        Preferences.set(.plusSupportUri, to: supportUri)
                    }

                    // Store human-readable status for UI; translation left to server-side if needed.
                    Preferences.set(.plusStatus, to: status)
                    Preferences.set(.plusStatusTranslated, to: status.capitalized)

                    success()

                case .failure(let error):
                    fail(error.localizedDescription)
                }
            }
    }
}
