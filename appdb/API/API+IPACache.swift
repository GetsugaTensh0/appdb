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

    static func getInstallHistory(success: @escaping (_ status: IPACacheStatus) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        AF.request(endpoint + "get_install_history", parameters: ["lang": languageCode], headers: headersWithCookie)
            .responseObject(keyPath: "data") { (response: AFDataResponse<IPACacheStatus>) in
                switch response.result {
                case .success(let result):
                    success(result)
                case .failure(let error):
                    fail(error as NSError)
                }
            }
    }


}
