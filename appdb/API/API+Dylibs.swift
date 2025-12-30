//
//  API+Dylibs.swift
//  appdb
//
//  Created by stev3fvcks on 19.03.23.
//  Copyright © 2023 stev3fvcks. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

extension API {

    static func getDylibs(success: @escaping (_ items: [String]) -> Void, fail: @escaping (_ error: String) -> Void) {
        // API 1.7: use Enhancements library as a replacement for legacy dylibs list
        let parameters: [String: Any] = [
            "lang": languageCode
        ]

        AF.request(endpoint + Actions.getEnhancements.rawValue, method: .post, parameters: parameters, headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        fail(json["errors"][0]["translated"].stringValue)
                    } else {
                        // Map enhancement objects to a display name similar to old dylib names
                        let names = json["data"].arrayValue.map { enhancement in
                            let name = enhancement["name"].stringValue
                            let version = enhancement["version"].stringValue
                            return version.isEmpty ? name : "\(name) (\(version))"
                        }
                        success(names)
                    }
                case .failure(let error):
                    fail(error.localizedDescription)
                }
            }
    }

    static func addDylib(url: String, success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        // API 1.7: add enhancement from URL
        AF.request(endpoint + Actions.addEnhancement.rawValue, method: .post, parameters: ["url": url, "lang": languageCode], headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        fail(json["errors"][0]["translated"].stringValue)
                    } else {
                        Preferences.set(.askForInstallationOptions, to: true)
                        success()
                    }
                case .failure(let error):
                    fail(error.localizedDescription)
                }
            }
    }

    static func uploadDylib(fileURL: URL, request: @escaping (_ r: Alamofire.UploadRequest) -> Void, completion: @escaping (_ error: String?) -> Void) {

        // API 1.7: upload enhancement archive as ZIP
        request(AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(fileURL, withName: "zip")
        }, to: endpoint + Actions.addEnhancement.rawValue, method: .post, headers: headersWithCookie).responseJSON { response in

            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if !json["success"].boolValue {
                    completion(json["errors"][0]["translated"].stringValue)
                } else {
                    completion(nil)
                }
            case .failure(let error):
                completion(error.localizedDescription)
            }
        })
    }

    static func deleteDylib(name: String, success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        // In API 1.7 `delete_enhancement` expects an enhancement id. Since the
        // legacy API exposed only names, we optimistically try to treat the
        // provided name as an id when it can be parsed as integer.
        var parameters: [String: Any] = ["lang": languageCode]
        if let id = Int(name) {
            parameters["id"] = id
        } else {
            // If we do not have a numeric id, fail with a clear message.
            fail("Cannot delete enhancement: identifier is not an id.")
            return
        }

        AF.request(endpoint + Actions.deleteEnhancement.rawValue, method: .post, parameters: parameters, headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        fail(json["errors"][0]["translated"].stringValue)
                    } else {
                        success()
                    }
                case .failure(let error):
                    fail(error.localizedDescription)
                }
            }
    }
}
