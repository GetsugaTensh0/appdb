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

    private static func installType(for type: ItemType) -> String {
        switch type {
        case .myAppstore:
            return "libraries"
        case .cydia:
            return "cydia"
        case .ios:
            return "ios"
        default:
            return "universal"
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
                        completion(json["errors"][0]["translated"].stringValue)
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

        func installWithTicket(_ ticket: String) {
            var ticketParameters = parameters
            ticketParameters["installation_ticket"] = ticket
            ticketParameters["type"] = "universal"
            performInstall(parameters: ticketParameters) { error in
                guard let error = error else {
                    completion(nil)
                    return
                }

                var legacyParameters: [String: Any] = [
                    "lang": languageCode,
                    "type": installType(for: type),
                    "id": id
                ]
                for (key, value) in additionalOptions { legacyParameters[key.rawValue] = value }
                performInstall(parameters: legacyParameters) { legacyError in
                    completion(legacyError ?? error)
                }
            }
        }

        if id.count >= 20, !id.allSatisfy({ $0.isHexDigit }) || id.count > 40 {
            installWithTicket(id)
            return
        }

        fetchGatewayObject(identifier: id, success: { json in
            let ticket = json["data"]["installation_ticket"].stringValue
            if ticket.isEmpty {
                let reason = json["data"]["no_installation_ticket_failure_reason"]["translated"].stringValue
                if reason.isEmpty {
                    var legacyParameters: [String: Any] = [
                        "lang": languageCode,
                        "type": installType(for: type),
                        "id": id
                    ]
                    for (key, value) in additionalOptions { legacyParameters[key.rawValue] = value }
                    performInstall(parameters: legacyParameters, completion: completion)
                } else {
                    completion(reason)
                }
            } else {
                installWithTicket(ticket)
            }
        }, fail: { error in
            var legacyParameters: [String: Any] = [
                "lang": languageCode,
                "type": installType(for: type),
                "id": id
            ]
            for (key, value) in additionalOptions { legacyParameters[key.rawValue] = value }
            performInstall(parameters: legacyParameters) { legacyError in
                completion(legacyError ?? error)
            }
        })
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
