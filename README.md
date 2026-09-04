<p align="center">
  <img src="https://user-images.githubusercontent.com/11541888/58876201-a370b100-86cd-11e9-962b-b46e823d1b54.png" alt="appdb icon" title="appdb" height=130>
</p>

# appdb

[![swift-version](https://img.shields.io/badge/swift-5-orange.svg)](https://github.com/apple/swift)
[![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)

A fully-featured iOS client for [appdb.to](https://appdb.to), written in Swift 5.

> **Updated for appdb.to API v1.7** — [Dustin Seehaver](https://github.com/GetsugaTensh0) ([@GetsugaTensh0](https://github.com/GetsugaTensh0)) updated this fork to work with the latest appdb.to API (v1.7), including the new POST/form-data request contract, UOID-based content identifiers, download queue fixes, and runtime error corrections.

This is a maintained fork of [n3d1117/appdb](https://github.com/n3d1117/appdb).

## Screenshots

<p align="center">
  <img src="https://user-images.githubusercontent.com/11541888/110785557-60ad1700-826b-11eb-989f-824cb31fd47f.png" alt="appdb screenshots" title="appdb" style="width=100%">
</p>
<p align="center">
  <img src="https://user-images.githubusercontent.com/11541888/110786620-a4ece700-826c-11eb-802a-c326f07696b7.png" alt="appdb screenshots" title="appdb" style="width=100%">
</p>

## Download

You can download the latest unsigned `.ipa` from the [Releases page](https://github.com/GetsugaTensh0/appdb/releases) or from [GitHub Actions artifacts](https://github.com/GetsugaTensh0/appdb/actions/workflows/build-unsigned-ipa.yml).

## Build Manually

```bash
git clone https://github.com/GetsugaTensh0/appdb.git
cd appdb/
open appdb.xcodeproj
```

Build and run in Xcode (iOS 14+). Dependencies are managed via Swift Package Manager and resolved automatically on first open.

## Dependencies

| Library | Description |
|---------|-------------|
| [Alamofire](https://github.com/Alamofire/Alamofire) | HTTP networking |
| [AlamofireImage](https://github.com/Alamofire/AlamofireImage) | Image loading for Alamofire |
| [AlamofireNetworkActivityIndicator](https://github.com/Alamofire/AlamofireNetworkActivityIndicator) | Network activity indicator |
| [BulletinBoard](https://github.com/alexaubry/BulletinBoard) | Contextual cards |
| [Cartography](https://github.com/robb/Cartography) | Declarative Auto Layout DSL |
| [Cosmos](https://github.com/evgenyneu/Cosmos) | Star rating control |
| [DeepDiff](https://github.com/onmyway133/DeepDiff) | Collection diffing |
| [Kanna](https://github.com/tid-kijyun/Kanna) | XML/HTML parser |
| [Localize-Swift](https://github.com/marmelroy/Localize-Swift) | In-app language switching |
| [ObjectMapper](https://github.com/tristanhimmelman/ObjectMapper) | JSON object mapping |
| [SwiftTheme](https://github.com/wxxsw/SwiftTheme) | Theme/skin manager |
| [Static](https://github.com/venmo/Static) | Static table views |
| [SwiftMessages](https://github.com/SwiftKickMobile/SwiftMessages) | In-app message bar |
| [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) | JSON handling |
| [swifter](https://github.com/httpswift/swifter) | Tiny HTTP server |
| [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) | ZIP handling |

## URL Schemes

The app registers the `appdb-ios://` URL scheme:

| URL | Action |
|-----|--------|
| `appdb-ios://?tab=featured` | Open Featured tab |
| `appdb-ios://?tab=search` | Open Search tab |
| `appdb-ios://?tab=downloads` | Open Downloads tab |
| `appdb-ios://?tab=settings` | Open Settings tab |
| `appdb-ios://?tab=updates` | Open Updates tab |
| `appdb-ios://?tab=news` | Open News tab |
| `appdb-ios://?tab=system_status` | Open System Status |
| `appdb-ios://?tab=device_status` | Open Device Status |
| `appdb-ios://?tab=wishes` | Open Wishes tab |
| `appdb-ios://?tab=custom_apps` | Open Custom Apps |
| `appdb-ios://?trackid=<id>&type=ios` | Open app details (`type`: `ios`, `cydia`, `books`) |
| `appdb-ios://?q=facebook&type=ios` | Search for an app |
| `appdb-ios://?url=https://appdb.to` | Open a URL in-app |
| `appdb-ios://?news_id=308` | Open a specific news article |
| `appdb-ios://?action=authorize&code=xxx` | Authorize device with link code |

## Credits

- **Original project** by [n3d1117](https://github.com/n3d1117) — [n3d1117/appdb](https://github.com/n3d1117/appdb)
- **API v1.7 update and maintenance** by [Dustin Seehaver](https://github.com/GetsugaTensh0) ([@GetsugaTensh0](https://github.com/GetsugaTensh0))

## License

MIT License. See [LICENSE](LICENSE) file for details.
