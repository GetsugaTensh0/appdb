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

    static func versionsFromGateway(_ json: JSON, fallbackIdentifier: String) -> [Version] {
        let object = json["data"]["object"]
        let ticket = json["data"]["installation_ticket"].stringValue
        let downloadTicket = json["data"]["download_ticket"].stringValue
        let versionNumber = object["version"].stringValue.isEmpty ? Global.tilde : object["version"].stringValue
        let host = object["source_name"].stringValue.isEmpty ? "appdb" : object["source_name"].stringValue
        let developer = object["developer_name"].stringValue.isEmpty ? "appdb" : object["developer_name"].stringValue
        let identifier = object["universal_object_identifier"].stringValue.isEmpty ? fallbackIdentifier : object["universal_object_identifier"].stringValue
        let installReason = strippedAPIMessage(json["data"]["no_installation_ticket_failure_reason"]["translated"].stringValue)
        let downloadReason = strippedAPIMessage(json["data"]["no_download_ticket_failure_reason"]["translated"].stringValue)
        let reason = downloadReason.isEmpty ? installReason : downloadReason
        let hasTicket = !ticket.isEmpty || !downloadTicket.isEmpty

        var version = Version(number: versionNumber)
        version.links.append(Link(
            link: downloadTicket.isEmpty ? "" : "ticket://\(downloadTicket)",
            cracker: "appdb",
            uploader: developer,
            host: host,
            id: ticket.isEmpty ? identifier : ticket,
            verified: true,
            di_compatible: true,
            hidden: false,
            is_compatible: hasTicket,
            isTicket: !downloadTicket.isEmpty,
            incompatibility_reason: reason
        ))
        return [version]
    }

    static func getLinks(type: ItemType, trackid: String, success: @escaping (_ items: [Version]) -> Void, fail: @escaping (_ error: String) -> Void) {
        _ = type
        fetchGatewayObject(identifier: trackid, success: { json in
            success(versionsFromGateway(json, fallbackIdentifier: trackid))
        }, fail: fail)
    }

    static func reportLink(id: String, type: ItemType, reason: String, completion: @escaping (_ error: String?) -> Void) {
        _ = id
        _ = type
        _ = reason
        completion("Link reporting endpoint was removed in API v1.7".localized())
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
