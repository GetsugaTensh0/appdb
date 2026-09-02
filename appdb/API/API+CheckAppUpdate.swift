//
//  API+CheckAppUpdate.swift
//  appdb
//
//  Created by ned on 28/05/2019.
//  Copyright © 2019 ned. All rights reserved.
//

import Foundation
import SwiftyJSON

extension API {

    static func checkIfUpdateIsAvailable(success: @escaping (CydiaApp, String) -> Void) {

        let currentVersion: String = Global.appVersion

        var params = searchIndexParameters(type: .cydia, order: .all, price: .all, genre: "0", dev: "0", q: "appdb", page: 1)
        params["length"] = 5
        post(.search, parameters: params)
            .responseJSON { response in
                guard case .success(let value) = response.result else { return }
                let json = JSON(value)
                let items = json["data"].arrayValue
                guard let match = items.first(where: { $0["name"].stringValue.lowercased().contains("appdb") }) else { return }
                let uoid = match["universal_object_identifier"].stringValue
                guard !uoid.isEmpty else { return }

                API.getItem(type: CydiaApp.self, identifier: uoid, success: { app in
                    if app.version.compare(currentVersion, options: .numeric) == .orderedDescending {
                        let installId = app.installationTicket.isEmpty ? (app.itemUoid.isEmpty ? uoid : app.itemUoid) : app.installationTicket
                        success(app, installId)
                    }
                }, fail: { _ in })
            }
    }
}
