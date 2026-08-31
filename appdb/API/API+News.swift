//
//  API+News.swift
//  appdb
//
//  Created by ned on 15/03/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit
import Alamofire

extension API {

    static func getNews(limit: Int = 10, success: @escaping (_ items: [SingleNews]) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        post(.getPages, parameters: ["category": Actions.newsCategory.rawValue, "length": String(limit)])
            .responseArray(keyPath: "data") { (response: AFDataResponse<[SingleNews]>) in
                switch response.result {
                case .success(let news):
                    success(news)
                case .failure(let error):
                    fail(error as NSError)
                }
            }
    }

    static func getNewsDetail(id: String, success: @escaping (_ item: SingleNews) -> Void, fail: @escaping (_ error: NSError) -> Void) {
        post(.getPages, parameters: ["category": Actions.newsCategory.rawValue, "id": id])
        .responseObject(keyPath: "data") { (response: AFDataResponse<SingleNews>) in
            switch response.result {
            case .success(let singleNews):
                success(singleNews)
            case .failure(let error):
                fail(error as NSError)
            }
        }
    }
}
