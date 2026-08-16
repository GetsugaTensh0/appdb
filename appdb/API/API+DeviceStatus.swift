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

    static func getDeviceStatus(success: @escaping (_ items: [DeviceStatusItem]) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        post(.getStatus)
            .responseArray(keyPath: "data") { (response: AFDataResponse<[DeviceStatusItem]>) in
                switch response.result {
                case .success(let results):
                    success(results)
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
