//
//  API+DeviceLink.swift
//  appdb
//
//  Created by ned on 10/04/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

extension API {

    static func linkAutomaticallyUsingUDID(success: @escaping () -> Void, fail: @escaping () -> Void) {

        guard let deviceUdid = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed")?["dbservicesUDID"] as? String else {
            fail()
            return
        }

        post(.link, parameters: ["type": "link", "email": "", "udid": deviceUdid, "client": "appdb unofficial client"])
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)

                    if !json["success"].boolValue {
                        fail()
                    } else {
                        let linkToken = json["data"]["link_token"].stringValue
                        guard !linkToken.isEmpty else {
                            fail()
                            return
                        }
                        Preferences.set(.token, to: linkToken)

                        API.getLinkCode(success: {
                            success()
                        }, fail: { _ in
                            fail()
                        })
                    }
                case .failure:
                    fail()
                }
            }
    }

    static func linkDevice(code: String, success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        post(.link, parameters: ["type": "control", "link_code": code])
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        fail(json["errors"][0]["translated"].stringValue)
                    } else {
                        Preferences.set(.token, to: json["data"]["link_token"].stringValue)

                        API.getLinkCode(success: {
                            success()
                        }, fail: { error in
                            fail(error)
                        })
                    }
                case .failure(let error):
                    fail(error.localizedDescription)
                }
            }
    }

    static func getLinkCode(success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        post(.getLinkCode)
        .responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if !json["success"].boolValue {
                    fail(json["errors"][0]["translated"].stringValue)
                } else {
                    Preferences.set(.linkCode, to: json["data"].stringValue)
                    success()
                }
            case .failure(let error):
                fail(error.localizedDescription)
            }
        }
    }

    static func emailLinkCode(email: String, success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        fail("Email link code is no longer available in API v1.7. Use the link code shown in Settings instead.".localized())
    }

    static func getAppdbAppsBundleIdsTicket(success: @escaping (_ ticket: String) -> Void, fail: @escaping (_ error: String) -> Void) {
        post(.getAppdbAppsBundleIdsTicket)
        .responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if !json["success"].boolValue {
                    fail(json["errors"][0]["translated"].stringValue)
                } else {
                    success(json["data"].stringValue)
                }
            case .failure(let error):
                fail(error.localizedDescription)
            }
        }
    }

    static func getAppdbAppsBundleIds(ticket: String, success: @escaping (_ bundleIds: [String]) -> Void, fail: @escaping (_ error: String, _ code: String) -> Void) {
        post(.getAppdbAppsBundleIds, parameters: ["t": ticket])
        .responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if !json["success"].boolValue {
                    fail(json["errors"][0]["translated"].stringValue, json["errors"][0]["code"].stringValue)
                } else {
                    success(json["data"].arrayValue.map { $0.stringValue})
                }
            case .failure(let error):
                fail(error.localizedDescription, "")
            }
        }
    }

    static func getAllLinkedDevices(success: @escaping (_ devices: [LinkedDevice]) -> Void, fail: @escaping (_ error: String) -> Void) {
        post(.getAllDevices)
            .responseArray(keyPath: "data") { (response: AFDataResponse<[LinkedDevice]>) in
                switch response.result {
                case .success(let devices):
                    success(devices)
                case .failure(let error as NSError):
                    fail(error.localizedDescription)
                }
            }
    }
}
