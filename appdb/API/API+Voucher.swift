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
        fail("Voucher activation is no longer available in API v1.7. Use subscription options instead.".localized())
    }

    static func validateVoucher(voucher: String, success: @escaping () -> Void, fail: @escaping (_ error: String) -> Void) {
        fail("Voucher validation is no longer available in API v1.7. Use subscription options instead.".localized())
    }
}
