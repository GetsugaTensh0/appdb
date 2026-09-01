//
//  API+Voucher.swift
//  appdb
//
//  Created by ned on 13/10/2019.
//  Copyright © 2019 ned. All rights reserved.
//

import Alamofire
import SwiftyJSON

extension API {

    static func activateVoucher(voucher: String, success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        post(.activatePro, parameters: ["voucher": voucher])
        .responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if !json["success"].boolValue {
                    fail(json["errors"][0]["translated"].stringValue)
                } else {
                    success()
                }
            case .failure(let error):
                fail(error.localizedDescription)
            }
        }
    }

    static func validateVoucher(voucher: String, success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        post(.validatePro, parameters: ["voucher": voucher])
        .responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if !json["success"].boolValue {
                    fail(json["errors"][0]["translated"].stringValue)
                } else {
                    success()
                }
            case .failure(let error):
                fail(error.localizedDescription)
            }
        }
    }
}
