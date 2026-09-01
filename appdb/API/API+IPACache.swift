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
        fail("This feature is no longer available".localized())
    }
}
