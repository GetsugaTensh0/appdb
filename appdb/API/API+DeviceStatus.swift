//
//  API+DeviceStatus.swift
//  appdb
//
//  Created by ned on 15/05/2018.
//  Copyright Â© 2018 ned. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

extension API {

    static func getDeviceStatus(uuids: [String] = [], sinceUuid: String = "", success: @escaping (_ items: [DeviceStatusItem]) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        var parameters: [String: Any] = [:]
        if !uuids.isEmpty { parameters["uuids"] = uuids }
        if !sinceUuid.isEmpty { parameters["since_uuid"] = sinceUuid }
        post(.getStatus, parameters: parameters)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    success(json["data"].arrayValue.map { DeviceStatusItem.parse($0) })
                case .failure(let error):
                    fail(error as NSError)
                }
            }
    }

    static func emptyCommandQueue(success: @escaping () -> Void) {
        post(.clear)
        .responseJSON { response in
            switch response.result {
            case .success:
                success()
            case .failure:
                break
            }
        }
    }

    static func fixCommand(uuid: String) {
        post(.cancelCommand, parameters: ["uuid": uuid])
            .responseJSON { _ in }
    }

    static func retryCommand(uuid: String) {
        post(.retryCommand, parameters: ["uuid": uuid])
            .responseJSON { _ in }
    }
}
