//
//  API+Promotions.swift
//  appdb
//
//  Created by ned on 26/01/2017.
//  Copyright © 2017 ned. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import ObjectMapper

extension API {

    static func getPromotions(success: @escaping (_ items: [Promotion]) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        post(.promotions)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        fail(NSError(domain: "appdb", code: 0, userInfo: [NSLocalizedDescriptionKey: json["errors"][0]["translated"].stringValue]))
                        return
                    }
                    let content = json["data"]["content"].arrayValue
                    let items = Mapper<Promotion>().mapArray(JSONArray: content.map { $0.dictionaryObject ?? [:] })
                    success(items)
                case .failure(let error):
                    fail(error as NSError)
                }
            }
    }
}
