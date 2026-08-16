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

        let trackid: String = "1900000538"
        let currentVersion: String = Global.appVersion

        API.getItem(type: CydiaApp.self, identifier: trackid, success: { app in
            if app.version.compare(currentVersion, options: .numeric) == .orderedDescending {
                let installId = app.installationTicket.isEmpty ? (app.itemUoid.isEmpty ? trackid : app.itemUoid) : app.installationTicket
                success(app, installId)
            }
        }, fail: { _ in })
    }
}
