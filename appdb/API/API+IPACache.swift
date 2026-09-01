//
//  API+IPACache.swift
//  appdb
//
//  Created by ned on 05/01/22.
//  Copyright Â© 2022 ned. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

extension API {

    static func getIPACacheStatus(success: @escaping (_ status: IPACacheStatus) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        post(.getIpaCacheStatus)
            .responseObject(keyPath: "data") { (response: AFDataResponse<IPACacheStatus>) in
                switch response.result {
                case .success(let result):
                    success(result)
                case .failure(let error):
                    fail(error as NSError)
                }
            }
    }

    static func reinstallEverything(success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        fail("Reinstall from cache was removed in API v1.7".localized())
    }

    static func clearIpaCache(success: @escaping () -> Void) {
        success()
    }

    static func deleteIpaFromCache(bundleId: String, success: @escaping () -> Void) {
        _ = bundleId
        success()
    }

    static func revalidateIpaCache(success: @escaping () -> Void) {
        success()
    }
}
