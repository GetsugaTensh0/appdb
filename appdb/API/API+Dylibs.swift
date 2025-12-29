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

    static func getEnhancements(success: @escaping (_ items: [String]) -> Void, fail: @escaping (_ error: String) -> Void) {
        AF.request(endpoint + "get_enhancements", parameters: ["lang": languageCode], headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        fail(json["errors"][0]["translated"].stringValue)
                    } else {
                        success(json["data"].arrayObject as? [String] ?? [])
                    }
                case .failure(let error):
                    fail(error.localizedDescription)
                }
            }
    }

    static func addEnhancement(url: String, success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        AF.request(endpoint + "add_enhancement", parameters: ["url": url, "lang": languageCode], headers: headersWithCookie)
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

    static func uploadEnhancement(fileURL: URL, request: @escaping (_ r: Alamofire.UploadRequest) -> Void, completion: @escaping (_ error: String?) -> Void) {

        request(AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(fileURL, withName: "enhancement")
        }, to: endpoint + "add_enhancement", method: .post, headers: headersWithCookie).responseJSON { response in

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

    static func deleteEnhancement(name: String, success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        AF.request(endpoint + "delete_enhancement", parameters: ["name": name, "lang": languageCode], headers: headersWithCookie)
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
