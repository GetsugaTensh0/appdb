//
//  API+IPACache.swift
//  appdb
//
//  Created by ned on 05/01/22.
//  Copyright © 2022 ned. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

extension API {

    static func getIPACacheStatus(success: @escaping (_ status: IPACacheStatus) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        // IPA cache endpoints were removed in API 1.7 and replaced with
        // installation history. For now, expose a friendly error so callers
        // can update their UI accordingly.
        let error = NSError(domain: "appdb", code: -1, userInfo: [NSLocalizedDescriptionKey: "IPA cache is no longer available on API v1.7."])
        fail(error)
    }

    static func reinstallEverything(success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        // Not supported in API 1.7.
        fail("Reinstalling everything from IPA cache is not available on API v1.7.")
    }

    static func clearIpaCache(success: @escaping () -> Void) {
        // Not supported in API 1.7.
        success()
    }

    static func deleteIpaFromCache(bundleId: String, success: @escaping () -> Void) {
        // Not supported in API 1.7.
        success()
    }

    static func revalidateIpaCache(success: @escaping () -> Void) {
        // Not supported in API 1.7.
        success()
    }
}
