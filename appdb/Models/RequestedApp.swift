//
//  RequestedApp.swift
//  appdb
//
//  Created by ned on 22/04/2019.
//  Copyright © 2019 ned. All rights reserved.
//

struct RequestedApp: Matchable, Codable, Equatable {

    var linkId: String = ""
    var type: ItemType = .ios
    var name: String = ""
    var status: String = ""
    var image: String = ""
    var bundleId: String = ""
    var commandUuid: String = ""
    var installationType: String = ""
    var manifestUri: String = ""

    init(type: ItemType, linkId: String, name: String, image: String, bundleId: String, status: String = "", commandUuid: String = "", installationType: String = "", manifestUri: String = "") {
        self.linkId = linkId
        self.type = type
        self.name = name
        self.image = image
        self.bundleId = bundleId
        self.status = status
        self.commandUuid = commandUuid
        self.installationType = installationType
        self.manifestUri = manifestUri
    }

    func match(with object: Any) -> Match {
        guard let app = object as? RequestedApp else { return .none }
        guard linkId == app.linkId else { return .none }
        return status == app.status ? .equal : .change
    }

    static func == (lhs: RequestedApp, rhs: RequestedApp) -> Bool {
        lhs.linkId == rhs.linkId
    }
}
