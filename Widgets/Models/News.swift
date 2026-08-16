//
//  News.swift
//  WidgetsExtension
//
//  Created by ned on 09/03/21.
//  Copyright © 2021 ned. All rights reserved.
//

import Foundation

struct News: Identifiable, Decodable {

    let id: Int
    let title: String
    let added: String

    enum CodingKeys: String, CodingKey {
        case id, title, added
    }

    init(id: Int, title: String, added: String) {
        self.id = id
        self.title = title
        self.added = added
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        if let timestamp = try? container.decode(Int.self, forKey: .added) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            added = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
        } else {
            added = try container.decodeIfPresent(String.self, forKey: .added) ?? ""
        }
    }

    static var dummy: News {
        News(id: 0, title: "Example News Title Goes Here", added: "Tue, 16 Feb 2021 14:30:48 +0000")
    }
}
