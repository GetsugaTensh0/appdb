//
//  API+Dylibs.swift
//  appdb
//
//  Created by stev3fvcks on 19.03.23.
//  Copyright Â© 2023 stev3fvcks. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

extension API {

    static var enhancementIdsByName: [String: Int] = [:]

    static func getDylibs(success: @escaping (_ items: [String]) -> Void, fail: @escaping (_ error: String) -> Void) {
        post(.getDylibs)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        fail(json["errors"][0]["translated"].stringValue)
                    } else {
                        enhancementIdsByName.removeAll()
                        let names = json["data"].arrayValue.compactMap { item -> String? in
                            let name = item["name"].stringValue.isEmpty ? item["title"].stringValue : item["name"].stringValue
                            guard !name.isEmpty else { return item.stringValue.isEmpty ? nil : item.stringValue }
                            let id = item["id"].intValue
                            if id != 0 { enhancementIdsByName[name] = id }
                            return name
                        }
                        success(names)
                    }
                case .failure(let error):
                    fail(error.localizedDescription)
                }
            }
    }

    static func addDylib(url: String, success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        post(.addDylib, parameters: ["url": url])
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

        request(AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(fileURL, withName: "dylib")
            if Preferences.deviceIsLinked, !Preferences.linkToken.isEmpty {
                multipartFormData.append(Preferences.linkToken.data(using: .utf8)!, withName: "lt")
            }
            multipartFormData.append(languageCode.data(using: .utf8)!, withName: "lang")
            multipartFormData.append("appdb".data(using: .utf8)!, withName: "brand")
        }, to: actionPath(.addDylib), method: .post, headers: headersWithCookie).responseJSON { response in

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
        var params: [String: Any] = ["name": name]
        if let id = enhancementIdsByName[name] {
            params["id"] = id
        }
        post(.deleteDylib, parameters: params)
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
