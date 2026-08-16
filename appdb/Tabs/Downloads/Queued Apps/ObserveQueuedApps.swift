//
//  ObserveQueuedApps.swift
//  appdb
//
//  Created by ned on 21/04/2019.
//  Copyright © 2019 ned. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

// Singleton to observe currently queued apps
// Profile-linked devices (itms-services) need get_status polling and an explicit install prompt.
// See https://rtfm.dbservices.to/#/migrations/mdm-to-profiles

class ObserveQueuedApps {

    static var shared = ObserveQueuedApps()
    private init() { }

    var requestedApps = [RequestedApp]()
    private var timer: Timer?
    private var numberOfQueuedApps: Int = 0

    private var ignoredInstallAppsUUIDs = [String]()
    private var ignoredLinkedDeviceInfoUUIDs = [String]()
    private var promptedUUIDs = [String]()

    var onUpdate: ((_ apps: [RequestedApp]) -> Void)?

    deinit {
        timer?.invalidate()
        timer = nil
    }

    func addApp(app: RequestedApp) {
        addApp(type: app.type, linkId: app.linkId, name: app.name, image: app.image, bundleId: app.bundleId, commandUuid: app.commandUuid, installationType: app.installationType)
    }

    func addApp(type: ItemType, linkId: String, name: String, image: String, bundleId: String, commandUuid: String = "", installationType: String = "") {
        let app = RequestedApp(type: type, linkId: linkId, name: name, image: image, bundleId: bundleId, status: "Waiting...".localized(), commandUuid: commandUuid, installationType: installationType)
        requestedApps.insert(app, at: 0)

        if timer == nil {
            updateAppsStatus()
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateAppsStatus), userInfo: nil, repeats: true)
        }

        UIApplication.shared.keyWindow?.rootViewController?.badgeAddOne(for: .downloads)

        numberOfQueuedApps += 1
        let numberOfQueuedAppsDict: [String: Int] = ["number": numberOfQueuedApps, "tab": 0]
        NotificationCenter.default.post(name: .UpdateQueuedSegmentTitle, object: self, userInfo: numberOfQueuedAppsDict)
    }

    func removeApp(linkId: String) {
        if let index = requestedApps.lastIndex(where: { $0.linkId == linkId || $0.commandUuid == linkId }) {
            requestedApps.remove(at: index)

            UIApplication.shared.keyWindow?.rootViewController?.badgeSubtractOne(for: .downloads)

            numberOfQueuedApps -= 1
            let numberOfQueuedAppsDict: [String: Int] = ["number": numberOfQueuedApps, "tab": 0]
            NotificationCenter.default.post(name: .UpdateQueuedSegmentTitle, object: self, userInfo: numberOfQueuedAppsDict)
        }
    }

    func removeAllApps() {
        self.requestedApps = []

        UIApplication.shared.keyWindow?.rootViewController?.updateBadge(with: nil, for: .downloads)

        numberOfQueuedApps = 0
        let numberOfQueuedAppsDict: [String: Int] = ["number": numberOfQueuedApps, "tab": 0]
        NotificationCenter.default.post(name: .UpdateQueuedSegmentTitle, object: self, userInfo: numberOfQueuedAppsDict)
    }

    func updateStatus(linkId: String, status: String) {
        if let index = requestedApps.firstIndex(where: { $0.linkId == linkId || $0.commandUuid == linkId }) {
            self.requestedApps[index].status = status
        }
    }

    @objc func updateAppsStatus() {
        if !requestedApps.isEmpty {
            API.getDeviceStatus(success: { [weak self] items in
                guard let self = self else { return }
                for app in self.requestedApps {
                    guard let item = self.matchingItem(for: app, in: items) else { continue }
                    self.apply(item: item, to: app)
                }
                self.onUpdate?(self.requestedApps)
            }, fail: { _ in })
        }
    }

    private func matchingItem(for app: RequestedApp, in items: [DeviceStatusItem]) -> DeviceStatusItem? {
        if !app.commandUuid.isEmpty, let match = items.first(where: { $0.uuid == app.commandUuid }) {
            return match
        }
        if !app.bundleId.isEmpty, let match = items.first(where: { !$0.bundleId.isEmpty && $0.bundleId == app.bundleId }) {
            return match
        }
        if !app.linkId.isEmpty, let match = items.first(where: { $0.linkId == app.linkId || $0.uoid == app.linkId }) {
            return match
        }
        if !app.name.isEmpty, let match = items.first(where: { $0.title.compare(app.name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) {
            return match
        }
        return nil
    }

    private func apply(item: DeviceStatusItem, to app: RequestedApp) {
        let usesItms = app.installationType == "itms-services" || Preferences.linkType == "profile" || !item.manifestUri.isEmpty
        let failed = item.status.contains("fail") || item.statusShort == "failed"
        let ready = item.status == "ok" || item.statusShort == "ok"

        if failed {
            let message = item.statusText.isEmpty ? item.status : parseLatestStatus(from: item)
            Messages.shared.showError(message: message.isEmpty ? "Installation failed, but can be fixed from Settings -> Device Status".localized() : message)
            if item.status == "failed_fixable" {
                // Keep the row so the user can open Device Status.
            }
            updateStatus(linkId: app.commandUuid.isEmpty ? app.linkId : app.commandUuid, status: message.isEmpty ? "Failed".localized() : message)
            if !usesItms {
                removeApp(linkId: app.linkId)
            }
            return
        }

        var newStatus: String
        if !item.statusText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newStatus = parseLatestStatus(from: item) + "..."
        } else {
            newStatus = friendlyStatus(item.status)
        }
        updateStatus(linkId: app.commandUuid.isEmpty ? app.linkId : app.commandUuid, status: newStatus)

        if usesItms {
            if ready, !item.manifestUri.isEmpty {
                promptInstall(from: item, app: app)
            } else if !item.downloadUri.isEmpty, app.installationType != "push" {
                promptDownload(from: item, app: app)
            }
            return
        }

        // MDM / push: the device receives the prompt itself.
        if item.type == "install_app", !ignoredInstallAppsUUIDs.contains(item.uuid) {
            ignoredInstallAppsUUIDs.append(item.uuid)
            removeApp(linkId: app.linkId)
        }
    }

    private func friendlyStatus(_ raw: String) -> String {
        switch raw.lowercased() {
        case "", "new": return "In queue".localized()
        case "acknowledged": return "Device received command".localized()
        case "ok", "done", "success": return "Ready to install".localized()
        case "failed", "failed_fixable": return "Failed".localized()
        default: return raw.isEmpty ? "Waiting...".localized() : raw
        }
    }

    private func promptInstall(from item: DeviceStatusItem, app: RequestedApp) {
        let key = item.uuid.isEmpty ? app.linkId : item.uuid
        guard !promptedUUIDs.contains(key) else { return }
        promptedUUIDs.append(key)

        guard let url = itmsURL(from: item.manifestUri) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: { [weak self] success in
                if success {
                    self?.updateStatus(linkId: app.commandUuid.isEmpty ? app.linkId : app.commandUuid, status: "Install prompt sent".localized())
                    delay(1.5) {
                        self?.removeApp(linkId: app.linkId)
                    }
                } else {
                    Messages.shared.showError(message: "Unable to open the iOS install prompt".localized())
                }
            })
        }
    }

    private func promptDownload(from item: DeviceStatusItem, app: RequestedApp) {
        let key = "dl-" + (item.uuid.isEmpty ? app.linkId : item.uuid)
        guard !promptedUUIDs.contains(key) else { return }
        promptedUUIDs.append(key)
        guard let url = URL(string: item.downloadUri) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
            self.updateStatus(linkId: app.commandUuid.isEmpty ? app.linkId : app.commandUuid, status: "Download ready".localized())
        }
    }

    private func itmsURL(from manifest: String) -> URL? {
        if manifest.hasPrefix("itms-services://") {
            return URL(string: manifest)
        }
        let encoded = manifest.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? manifest
        return URL(string: "itms-services://?action=download-manifest&url=\(encoded)")
    }

    fileprivate func parseLatestStatus(from item: DeviceStatusItem) -> String {
        if item.statusText.components(separatedBy: "<br/> ").count == 2 {
            return item.statusText.components(separatedBy: "<br/>").first!
        } else if let latestStatus = item.statusText
                    .components(separatedBy: "<br/>").last?
                    .components(separatedBy: "\n").first {
            if latestStatus.isEmpty {
                return item.statusText
                    .components(separatedBy: "<br/>").dropLast().last ?? item.statusText
            }
            return latestStatus
        } else {
            return item.statusText
        }
    }
}
