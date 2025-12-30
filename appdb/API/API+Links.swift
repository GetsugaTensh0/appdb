//
//  API+Links.swift
//  appdb
//
//  Created by ned on 18/03/2017.
//  Copyright © 2017 ned. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

extension API {

    static func getLinks(universalObjectIdentifier: String, success: @escaping (_ items: [Version]) -> Void, fail: @escaping (_ error: String) -> Void) {
        guard !universalObjectIdentifier.isEmpty else {
            fail("Invalid content identifier")
            return
        }

        let parameters: [String: Any] = [
            "universal_object_identifier": universalObjectIdentifier,
            "lang": languageCode
        ]

        AF.request(endpoint + Actions.universalGateway.rawValue, method: .post, parameters: parameters, headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)

                    guard json["success"].boolValue else {
                        if let translated = json["errors"].arrayValue.first?["translated"].string, !translated.isEmpty {
                            fail(translated)
                        } else {
                            fail("Unknown error")
                        }
                        return
                    }

                    let data = json["data"]
                    let object = data["object"]

                    var versions: [Version] = []

                    let versionNumber = object["version"].stringValue
                    var version = Version(number: versionNumber.isEmpty ? Global.tilde : versionNumber)

                    let downloadTicket = data["download_ticket"].stringValue
                    let installationTicket = data["installation_ticket"].intValue
                    let noDownloadReason = data["no_download_ticket_failure_reason"]["translated"].stringValue

                    if !downloadTicket.isEmpty {
                        let id = object["id"].stringValue
                        let host = "appdb"
                        let name = object["name"].stringValue
                        let developerName = object["developer_name"].stringValue
                        let sourceName = object["source_name"].stringValue

                        let isCompatible = installationTicket == 1
                        let incompatibilityReason = isCompatible ? "" : noDownloadReason

                        let link = Link(
                            link: "ticket://\(downloadTicket)",
                            cracker: developerName.isEmpty ? sourceName : developerName,
                            uploader: developerName.isEmpty ? "appdb" : developerName,
                            host: host,
                            id: id,
                            verified: true,
                            di_compatible: isCompatible,
                            hidden: false,
                            is_compatible: isCompatible,
                            isTicket: true,
                            incompatibility_reason: incompatibilityReason,
                            report_reason: ""
                        )

                        version.links.append(link)
                    }

                    if !version.links.isEmpty {
                        versions.append(version)
                    }

                    success(versions)

                case .failure(let error):
                    fail(error.localizedDescription)
                }
            }
    }

    static func reportLink(id: String, type: ItemType, reason: String, completion: @escaping (_ error: String?) -> Void) {
        // In API v1.7 the old `report` endpoint was removed in favor of copyright
        // reporting flows that require additional context (including CAPTCHA).
        // For now, expose a friendly error so the UI can inform the user.
        completion("Reporting links is not available on API v1.7.")
    }

    static func getRedirectionTicket(t: String, completion: @escaping (_ error: String?, _ rt: String?, _ wait: Int?) -> Void) {

        guard var ticket = t.components(separatedBy: "ticket://").last else { return }

        // If I don't do this, '%3D' gets encoded to '%253D' which makes the ticket invalid
        ticket = ticket.replacingOccurrences(of: "%3D", with: "=")

        AF.request(endpoint + Actions.processRedirect.rawValue, parameters: ["t": ticket, "lang": languageCode], headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        completion(json["errors"][0]["translated"].stringValue, nil, nil)
                    } else {
                        let rt: String = json["data"]["redirection_ticket"].stringValue
                        let wait: Int = json["data"]["wait"].intValue
                        completion(nil, rt, wait)
                    }
                case .failure(let error):
                    completion(error.localizedDescription, nil, nil)
                }
            }
    }

    static func getPlainTextLink(rt: String, completion: @escaping (_ error: String?, _ link: String?) -> Void) {
        AF.request(endpoint + Actions.processRedirect.rawValue, parameters: ["rt": rt, "lang": languageCode], headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        completion(json["errors"][0]["translated"].stringValue, nil)
                    } else {
                        completion(nil, json["data"]["link"].stringValue)
                    }
                case .failure(let error):
                    completion(error.localizedDescription, nil)
                }
            }
    }
}
