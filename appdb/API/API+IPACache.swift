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
import ObjectMapper

extension API {

    static func getIPACacheStatus(success: @escaping (_ status: IPACacheStatus) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        post(.getIpaCacheStatus)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        let msg = json["errors"][0]["translated"].stringValue
                        fail(NSError(domain: "appdb", code: 0, userInfo: [NSLocalizedDescriptionKey: msg]))
                        return
                    }
                    let records = json["data"].arrayValue
                    let ipas: [CachedIPA] = records.compactMap { record in
                        let obj = record["object"]
                        guard obj.exists(), obj.type != .null else { return nil }
                        var dict: [String: Any] = [
                            "name": obj["name"].stringValue,
                            "bundle_id": obj["bundle_id"].stringValue,
                            "size": obj["size"].intValue,
                            "size_hr": obj["size_hr"].stringValue
                        ]
                        let queued = record["queued_at"].intValue
                        if queued > 0 { dict["added_at"] = String(queued) }
                        return Mapper<CachedIPA>().map(JSON: dict)
                    }
                    var status = IPACacheStatus(map: Map(mappingType: .fromJSON, JSON: [:]))!
                    status.ipas = ipas
                    status.sizeHr = ""
                    status.sizeLimitHr = ""
                    success(status)
                case .failure(let error):
                    fail(error as NSError)
                }
            }
    }

    static func reinstallEverything(success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        fail("This feature is no longer available".localized())
    }
}
