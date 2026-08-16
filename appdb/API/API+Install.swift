//
//  API+Install.swift
//  appdb
//
//  Created by ned on 28/09/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

extension API {

    static func getInstallationOptions(success: @escaping (_ items: [InstallationOption]) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        AF.request(endpoint + Actions.getFeatures.rawValue, parameters: ["lang": languageCode], headers: headersWithCookie)
            .responseArray(keyPath: "data") { (response: AFDataResponse<[InstallationOption]>) in
                switch response.result {
                case .success(let installationOptions):
                    success(installationOptions)
                case .failure(let error as NSError):
                    fail(error)
                }
            }
    }

    private static func performInstall(parameters: [String: Any], completion: @escaping (_ error: String?) -> Void) {
        AF.request(endpoint + Actions.install.rawValue, parameters: parameters, headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if json["success"].boolValue {
                        completion(nil)
                    } else {
                        completion(strippedAPIMessage(json["errors"][0]["translated"].stringValue))
                    }
                case .failure(let error):
                    completion(error.localizedDescription)
                }
            }
    }

    static func install(id: String, type: ItemType, additionalOptions: [AdditionalInstallationParameters: Any] = [:], completion: @escaping (_ error: String?) -> Void) {
        var parameters: [String: Any] = [
            "lang": languageCode,
            "type": type == .myAppstore ? "libraries" : "universal"
        ]
        for (key, value) in additionalOptions { parameters[key.rawValue] = value }

        if type == .myAppstore {
            parameters["id"] = id
            performInstall(parameters: parameters, completion: completion)
            return
        }

        // v1.7 deleted type=ios / type=cydia. Install is type=universal plus a ticket or UOID.
        if isUniversalObjectIdentifier(id) {
            parameters["universal_object_identifier"] = id
        } else if !id.isEmpty {
            parameters["installation_ticket"] = id
        } else {
            completion("Please authorize app from Settings first".localized())
            return
        }
        performInstall(parameters: parameters, completion: completion)
    }

    static func customInstall(ipaUrl: String, type: ItemType, iconUrl: String, bundleId: String, name: String, additionalOptions: [AdditionalInstallationParameters: Any] = [:], completion: @escaping (_ error: String?) -> Void) {
        var parameters: [String: Any] = [
            "type": "universal",
            "link": ipaUrl,
            "image": iconUrl,
            "bundle_id": bundleId,
            "name": name,
            "lang": languageCode
        ]
        _ = type
        for (key, value) in additionalOptions { parameters[key.rawValue] = value }
        performInstall(parameters: parameters, completion: completion)
    }

    static func requestInstallJB(plist: String, icon: String, link: String, completion: @escaping (_ error: String?) -> Void) {
        AF.request(endpoint + Actions.customInstall.rawValue, method: .post, parameters: ["plist": plist, "icon": icon, "link": link, "lang": languageCode], headers: headersWithCookie)
            .responseJSON { response in
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
            }
    }

    static func getPlistFromItmsHelper(bundleId: String, localIpaUrlString: String, title: String, completion: @escaping (_ plistUrl: String?) -> Void) {
        let urlString = itmsHelperEndpoint + "?i=%20&b=\(bundleId)&l=\(localIpaUrlString)&n=\(title)"
        completion(urlString.urlEncoded)
    }
}
