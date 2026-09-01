//
//  API+Genres.swift
//  appdb
//
//  Created by ned on 11/01/2017.
//  Copyright Â© 2017 ned. All rights reserved.
//

import Alamofire
import SwiftyJSON

extension API {

    // MARK: - Genres

    static func listGenres(completion: @escaping () -> Void) {
        post(.listGenres)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)

                    var genres: [Genre] = []
                    let data = json["data"]

                    // Default genres
                    genres.append(Genre(category: "ios", id: "0", name: "All Categories".localized()))
                    genres.append(Genre(category: "cydia", id: "0", name: "All Categories".localized()))
                    genres.append(Genre(category: "books", id: "0", name: "All Categories".localized()))

                    // API 1.7 exposes `official` genres; mirror across legacy tabs.
                    let officialGenres = data["official"].arrayValue

                    // Cydia genres
                    for value in officialGenres {
                        genres.append(
                            Genre(category: "cydia", id: value["id"].intValue.description, name: value["name"].stringValue, amount: value["content_amount"].stringValue)
                        )
                    }

                    // iOS Genres
                    for value in officialGenres {
                        genres.append(
                            Genre(category: "ios", id: value["id"].stringValue, name: value["name"].stringValue, amount: value["content_amount"].stringValue)
                        )
                    }

                    // Books Genres
                    for value in officialGenres {
                        genres.append(
                            Genre(category: "books", id: value["id"].stringValue, name: value["name"].stringValue, amount: value["content_amount"].stringValue)
                        )
                    }

                    // Remove delete genres
                    if let index = Preferences.genres.firstIndex(where: { !genres.contains($0) }) {
                        Preferences.remove(.genres, at: index)
                    }

                    guard !genres.isEmpty else { completion(); return }

                    // Save genres
                    for (index, var genre) in genres.enumerated() {
                        guard let type = ItemType(rawValue: genre.category) else { return }

                        if let index = Preferences.genres.firstIndex(where: { $0.compound == genre.compound }) {
                            // Genre exists
                            if Preferences.genres[index].icon.isEmpty {
                                getIcon(id: genre.id, type: type, completion: { icon in
                                    genre.icon = icon
                                    Preferences.remove(.genres, at: index)
                                    Preferences.append(.genres, element: genre)
                                })
                            }
                        } else {
                            // Genre does not exist
                            getIcon(id: genre.id, type: type, completion: { icon in
                                genre.icon = icon
                                Preferences.append(.genres, element: genre)
                            })
                        }

                        if index == genres.count - 1 {
                            completion()
                        }
                    }

                case .failure:
                    break
                }
            }
    }

    static func getIcon(id: String, type: ItemType, completion: @escaping (String) -> Void) {
        var parameters: [String: Any] = [
            "length": 1,
            "start": 0,
            "lang": languageCode
        ]
        if let contentType = v17ContentType(for: type) {
            parameters["type"] = contentType
        }
        if id != "0", let genreId = Int(id) {
            parameters["genre_id"] = genreId
        }
        post(.search, parameters: parameters)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    let icon = json["data"][0]["icon_uri"].stringValue
                    completion(icon.isEmpty ? json["data"][0]["image"].stringValue : icon)
                case .failure:
                    completion("")
                }
            }
    }

    static func categoryFromId(id: String, type: ItemType) -> String {
        if let genre = Preferences.genres.first(where: { $0.category == type.rawValue && $0.id == id }) {
            return genre.name
        } else {
            return ""
        }
    }

    static func idFromCategory(name: String, type: ItemType) -> String {
        if let genre = Preferences.genres.first(where: { $0.category == type.rawValue && $0.name == name }) {
            return genre.id
        } else {
            return ""
        }
    }
}
