//
//  App.swift
//  WidgetsExtension
//
//  Created by ned on 08/03/21.
//  Copyright © 2021 ned. All rights reserved.
//

import Foundation

struct Content: Identifiable, Decodable {

    let name: String
    let image: String
    let id: String

    enum CodingKeys: String, CodingKey {
        case name
        case image
        case iconUri = "icon_uri"
        case id
        case universalObjectIdentifier = "universal_object_identifier"
    }

    init(id: String, name: String, image: String) {
        self.id = id
        self.name = name
        self.image = image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        let icon = try container.decodeIfPresent(String.self, forKey: .iconUri)
        let legacyImage = try container.decodeIfPresent(String.self, forKey: .image)
        image = icon?.isEmpty == false ? icon! : (legacyImage ?? "")
        if let uoid = try container.decodeIfPresent(String.self, forKey: .universalObjectIdentifier), !uoid.isEmpty {
            id = uoid
        } else if let numeric = try container.decodeIfPresent(Int.self, forKey: .id) {
            id = String(numeric)
        } else {
            id = try container.decodeIfPresent(String.self, forKey: .id) ?? name
        }
    }

    static var dummy: Content {
        Content(id: "0", name: "Example Name", image: "")
    }
}
