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

struct InstallResult {
    let commandUuid: String
    let installationType: String
    let historyUuid: String
}

extension API {

    static func getInstallationOptions(success: @escaping (_ items: [InstallationOption]) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        post(.getFeatures)
            .responseArray(keyPath: "data") { (response: AFDataResponse<[InstallationOption]>) in
                switch response.result {
                case .success(let installationOptions):
                    success(installationOptions)
                case .failure(let error as NSError):
                    fail(error)
                }
            }
    }

    private static func performInstall(parameters: [String: Any], completion: @escaping (_ error: String?, _ result: InstallResult?) -> Void) {
        guard Preferences.deviceIsLinked, !Preferences.linkToken.isEmpty else {
            completion("Please authorize app from Settings first".localized(), nil)
            return
        }
        post(.install, parameters: parameters)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if json["success"].boolValue {
                        let data = json["data"]
                        completion(nil, InstallResult(
                            commandUuid: data["command_uuid"].stringValue,
                            installationType: data["installation_type"].stringValue,
                            historyUuid: data["installation_history_uuid"].stringValue
                        ))
                    } else {
                        completion(strippedAPIMessage(json["errors"][0]["translated"].stringValue), nil)
                    }
                case .failure(let error):
                    completion(error.localizedDescription, nil)
                }
            }
    }

    static func install(id: String, type: ItemType, additionalOptions: [AdditionalInstallationParameters: Any] = [:], asIpaFile: Bool = false, completion: @escaping (_ error: String?, _ result: InstallResult?) -> Void) {
        var parameters: [String: Any] = [
            "type": "universal"
        ]
        for (key, value) in additionalOptions { parameters[key.rawValue] = value }
        if asIpaFile { parameters["as_ipa_file"] = 1 }
        _ = type

        func installWithTicket(_ ticket: String) {
            guard !ticket.isEmpty else {
                completion("Please authorize app from Settings first".localized(), nil)
                return
            }
            var ticketParameters = parameters
            ticketParameters["installation_ticket"] = ticket
            performInstall(parameters: ticketParameters, completion: completion)
        }

        // Spec: /install/ takes installation_ticket from /universal_gateway/, not a UOID.
        if !isUniversalObjectIdentifier(id), !id.isEmpty {
            installWithTicket(id)
            return
        }

        fetchGatewayObject(identifier: id, success: { json in
            let ticket = json["data"]["installation_ticket"].stringValue
            if ticket.isEmpty {
                let reason = strippedAPIMessage(json["data"]["no_installation_ticket_failure_reason"]["translated"].stringValue)
                completion(reason.isEmpty ? "Please authorize app from Settings first".localized() : reason, nil)
            } else {
                installWithTicket(ticket)
            }
        }, fail: { completion($0, nil) })
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
        performInstall(parameters: parameters) { error, _ in completion(error) }
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
