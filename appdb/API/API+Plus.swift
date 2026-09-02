//
//  API+Plus.swift
//  appdb
//
//  Created by stev3fvcks on 19.03.23.
//  Copyright © 2023 stev3fvcks. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import ObjectMapper

extension API {

    static func getPlusPurchaseOptions(success: @escaping (_ items: [PlusPurchaseOption]) -> Void, fail: @escaping (_ error: String) -> Void) {
        post(.getSideloadingOptions)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        fail(json["errors"][0]["translated"].stringValue)
                        return
                    }
                    var options: [PlusPurchaseOption] = []
                    for method in json["data"].arrayValue {
                        let methodName = method["name"].stringValue.isEmpty
                            ? String(method["name"].intValue)
                            : method["name"].stringValue
                        let requiresLink = method["requires_device_link"].intValue == 1
                        for option in method["options"].arrayValue {
                            var opt = PlusPurchaseOption(map: Map(mappingType: .fromJSON, JSON: [:]))!
                            opt.type = methodName
                            opt.name = option["name"].stringValue
                            opt.price = option["price"].stringValue
                            opt.html = option["html"].stringValue
                            opt.requiresDeviceLink = requiresLink
                            options.append(opt)
                        }
                    }
                    success(options)
                case .failure(let error):
                    fail(error.localizedDescription)
                }
            }
    }

    static func refreshSubscriptionStatus(completion: @escaping () -> Void) {
        post(.getSubscriptions)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if json["success"].boolValue {
                        let subscriptions = json["data"].arrayValue
                        let active = subscriptions.first { $0["status"].stringValue == "active" }
                        let sub = active ?? subscriptions.first

                        if let sub = sub {
                            let isActive = sub["status"].stringValue == "active"
                            let expiresAt = sub["expires_at"].stringValue
                            if !expiresAt.isEmpty {
                                let expiry = expiresAt.unixToDate
                                Preferences.set(.isPlus, to: expiry.timeIntervalSince1970 > Date().timeIntervalSince1970)
                                Preferences.set(.plusUntil, to: expiresAt)
                            } else {
                                Preferences.set(.isPlus, to: isActive)
                            }
                            if !sub["status"].stringValue.isEmpty {
                                Preferences.set(.plusStatus, to: sub["status"].stringValue)
                            }
                            if !sub["provider"].stringValue.isEmpty {
                                Preferences.set(.plusProvider, to: sub["provider"].stringValue)
                            }
                        } else if subscriptions.isEmpty {
                            Preferences.set(.isPlus, to: false)
                        }
                    }
                case .failure:
                    break
                }
                completion()
            }
    }
}
