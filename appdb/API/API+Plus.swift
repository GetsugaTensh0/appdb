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

extension API {

    static func getPlusPurchaseOptions(success: @escaping (_ items: [PlusPurchaseOption]) -> Void, fail: @escaping (_ error: String) -> Void) {
        post(.getPlusPurchaseOptions)
            .responseArray(keyPath: "data") { (response: AFDataResponse<[PlusPurchaseOption]>) in
                switch response.result {
                case .success(let plusPurchaseOptions):
                    success(plusPurchaseOptions)
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
                        let data = json["data"]
                        let plusActive = data["is_plus"].stringValue == "yes" || data["status"].stringValue == "active"
                        let plusUntil = data["plus_till"].stringValue.isEmpty ? data["expires_at"].stringValue : data["plus_till"].stringValue
                        if !plusUntil.isEmpty {
                            let expiry = plusUntil.unixToDate
                            Preferences.set(.isPlus, to: expiry.timeIntervalSince1970 > Date().timeIntervalSince1970)
                            Preferences.set(.plusUntil, to: plusUntil)
                        } else {
                            Preferences.set(.isPlus, to: plusActive)
                        }
                        if !data["status"].stringValue.isEmpty {
                            Preferences.set(.plusStatus, to: data["status"].stringValue)
                        }
                        if !data["status_translated"].stringValue.isEmpty {
                            Preferences.set(.plusStatusTranslated, to: data["status_translated"].stringValue)
                        }
                        if !data["provider"].stringValue.isEmpty {
                            Preferences.set(.plusProvider, to: data["provider"].stringValue)
                        }
                    }
                case .failure:
                    break
                }
                completion()
            }
    }
}
