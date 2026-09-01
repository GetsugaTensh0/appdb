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
            timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateAppsStatus), userInfo: nil, repeats: true)
        }

        Global.mainWindow?.rootViewController?.badgeAddOne(for: .downloads)

        numberOfQueuedApps += 1
        let numberOfQueuedAppsDict: [String: Int] = ["number": numberOfQueuedApps, "tab": 0]
        NotificationCenter.default.post(name: .UpdateQueuedSegmentTitle, object: self, userInfo: numberOfQueuedAppsDict)
    }

    func removeApp(linkId: String) {
        if let index = requestedApps.lastIndex(where: { $0.linkId == linkId || $0.commandUuid == linkId }) {
            requestedApps.remove(at: index)

            Global.mainWindow?.rootViewController?.badgeSubtractOne(for: .downloads)

            numberOfQueuedApps -= 1
            let numberOfQueuedAppsDict: [String: Int] = ["number": numberOfQueuedApps, "tab": 0]
            NotificationCenter.default.post(name: .UpdateQueuedSegmentTitle, object: self, userInfo: numberOfQueuedAppsDict)
        }
        if requestedApps.isEmpty {
            timer?.invalidate()
            timer = nil
        }
    }

    func removeAllApps() {
        self.requestedApps = []

        Global.mainWindow?.rootViewController?.updateBadge(with: nil, for: .downloads)

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
        guard !requestedApps.isEmpty else { return }

        let commandUuids = requestedApps.map { $0.commandUuid }.filter { !$0.isEmpty }

        if !commandUuids.isEmpty {
            API.getDeviceStatus(uuids: commandUuids, success: { [weak self] items in
                self?.ingest(items)
            }, fail: { _ in })
        } else {
            API.getDeviceStatus(success: { [weak self] items in
                self?.ingest(items)
            }, fail: { _ in })
        }
    }

    func openInstallPrompt(for app: RequestedApp) {
        openInstallPrompt(manifest: app.manifestUri, linkId: app.commandUuid.isEmpty ? app.linkId : app.commandUuid)
    }

    func openInstallPrompt(manifest: String, linkId: String = "") {
        guard !manifest.isEmpty, let url = itmsURL(from: manifest) else {
            DispatchQueue.main.async {
                Messages.shared.showError(message: "Install file is not ready yet".localized())
            }
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: { [weak self] success in
                if success {
                    if !linkId.isEmpty {
                        self?.updateStatus(linkId: linkId, status: "Install prompt sent".localized())
                    }
                } else if let https = URL(string: manifest), https.scheme == "https" {
                    UIApplication.shared.open(https)
                } else {
                    Messages.shared.showError(message: "Unable to open the iOS install prompt".localized())
                }
            })
        }
    }

    private func ingest(_ items: [DeviceStatusItem]) {
        guard !items.isEmpty else { return }
        let apps = requestedApps
        for app in apps {
            let matches = matchingItems(for: app, in: items)
            if matches.isEmpty {
                if let ready = items.first(where: { !$0.manifestUri.isEmpty && self.looksRelated($0, to: app) }) {
                    apply(item: ready, to: app)
                } else if requestedApps.count == 1, let orphan = items.first(where: { !$0.manifestUri.isEmpty || $0.isReadyToInstall || !$0.statusText.isEmpty || $0.type.contains("install") || $0.type.contains("sign") }) {
                    apply(item: orphan, to: app)
                }
            } else {
                for item in matches { apply(item: item, to: app) }
                let stored = self.requestedApps.first(where: { $0.linkId == app.linkId || $0.commandUuid == app.commandUuid })
                if stored?.manifestUri.isEmpty != false, let ready = items.first(where: { !$0.manifestUri.isEmpty && (self.looksRelated($0, to: app) || $0.isReadyToInstall) }) {
                    apply(item: ready, to: app)
                }
            }
        }
        onUpdate?(requestedApps)
    }

    private func looksRelated(_ item: DeviceStatusItem, to app: RequestedApp) -> Bool {
        if !app.commandUuid.isEmpty, item.uuid == app.commandUuid { return true }
        if !app.bundleId.isEmpty, !item.bundleId.isEmpty, item.bundleId == app.bundleId { return true }
        if !app.linkId.isEmpty, item.linkId == app.linkId || item.uoid == app.linkId { return true }
        if !app.name.isEmpty, !item.title.isEmpty, item.title.compare(app.name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame { return true }
        return false
    }

    private func matchingItems(for app: RequestedApp, in items: [DeviceStatusItem]) -> [DeviceStatusItem] {
        items.filter { looksRelated($0, to: app) }
    }

    private func apply(item: DeviceStatusItem, to app: RequestedApp) {
        let usesItms = app.installationType != "push"
        let failed = item.isFailed

        if !item.manifestUri.isEmpty, let index = requestedApps.firstIndex(where: { $0.linkId == app.linkId || $0.commandUuid == app.commandUuid }) {
            requestedApps[index].manifestUri = item.manifestUri
        }

        if failed {
            let message = item.statusText.isEmpty ? item.status : parseLatestStatus(from: item)
            Messages.shared.showError(message: message.isEmpty ? "Installation failed, but can be fixed from Settings -> Device Status".localized() : message)
            updateStatus(linkId: app.commandUuid.isEmpty ? app.linkId : app.commandUuid, status: message.isEmpty ? "Failed".localized() : message)
            removeApp(linkId: app.linkId)
            return
        }

        if !item.manifestUri.isEmpty {
            let linkKey = app.commandUuid.isEmpty ? app.linkId : app.commandUuid
            updateStatus(linkId: linkKey, status: "Signed. Tap to install.".localized())
            offerInstall(from: item, app: app)
            if ["ok", "done", "success"].contains(item.status.lowercased()) {
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

        if usesItms, item.isReadyToInstall {
            updateStatus(linkId: app.commandUuid.isEmpty ? app.linkId : app.commandUuid, status: "Signed. Waiting for install file...".localized())
        }

        if usesItms, !item.downloadUri.isEmpty {
            promptDownload(from: item, app: app)
            return
        }

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

    private func offerInstall(from item: DeviceStatusItem, app: RequestedApp) {
        let key = item.uuid.isEmpty ? app.linkId : item.uuid
        guard !promptedUUIDs.contains(key) else { return }
        promptedUUIDs.append(key)

        var ready = app
        ready.manifestUri = item.manifestUri
        DispatchQueue.main.async {
            guard let host = UIApplication.topViewController() else {
                return
            }
            let alert = UIAlertController(
                title: "Ready to install".localized(),
                message: "%@ has been signed. Tap Install to show the iOS install popup.".localizedFormat(app.name),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Later".localized(), style: .cancel))
            alert.addAction(UIAlertAction(title: "Install".localized(), style: .default) { _ in
                self.openInstallPrompt(for: ready)
            })
            host.present(alert, animated: true)
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
        let trimmed = manifest.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("itms-services://") {
            return URL(string: trimmed)
        }
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: allowed) ?? trimmed
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
