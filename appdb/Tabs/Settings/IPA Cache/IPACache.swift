//
//  IPACache.swift
//  appdb
//
//  Created by ned on 05/01/22.
//  Copyright Â© 2022 ned. All rights reserved.
//

import UIKit

class IPACache: LoadingTableView {

    var status: IPACacheStatus? {
        didSet {
            self.tableView.spr_endRefreshing()
            self.state = .done
        }
    }

    convenience init() {
        if #available(iOS 13.0, *) {
            self.init(style: .insetGrouped)
        } else {
            self.init(style: .grouped)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Install History".localized()

        tableView.register(SimpleStaticCell.self, forCellReuseIdentifier: "cell")
        tableView.estimatedRowHeight = 50

        tableView.theme_separatorColor = Color.borderColor
        tableView.theme_backgroundColor = Color.tableViewBackgroundColor
        view.theme_backgroundColor = Color.tableViewBackgroundColor

        animated = false
        showsErrorButton = false
        showsSpinner = false

        // Hide last separator
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))

        if Global.isIpad {
            // Add 'Dismiss' button for iPad
            let dismissButton = UIBarButtonItem(title: "Dismiss".localized(), style: .done, target: self, action: #selector(self.dismissAnimated))
            self.navigationItem.rightBarButtonItems = [dismissButton]
        }

        // Refresh action
        tableView.spr_setIndicatorHeader { [weak self] in
            self?.fetchStatus()
        }

        tableView.spr_beginRefreshing()
    }

    private func fetchStatus() {
        API.getIPACacheStatus { [weak self] status in
            guard let self = self else { return }
            self.status = status
        } fail: { [weak self] error in
            guard let self = self else { return }
            self.status = nil
            self.showErrorMessage(text: "Cannot connect".localized(), secondaryText: error.localizedDescription, animated: false)
        }
    }

    @objc func dismissAnimated() { dismiss(animated: true) }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        status == nil ? 0 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        status == nil
            ? 0
            : section == 0 ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? SimpleStaticCell, let status = status {
            if (indexPath.section == 0) {
                cell.textLabel?.text = "Install History Items".localized()
                cell.detailTextLabel?.text = "\(status.ipas.count)"
                cell.textLabel?.theme_textColor = Color.title
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
            } else {
                switch indexPath.row {
                case 0:
                    cell.textLabel?.text = "Size".localized()
                    cell.detailTextLabel?.text = status.sizeHr + " / " + status.sizeLimitHr
                    cell.textLabel?.theme_textColor = Color.title
                    cell.selectionStyle = .none
                case 1:
                    cell.textLabel?.text = "In Update".localized()
                    cell.detailTextLabel?.text = status.inUpdate == 1 ? "Yes".localized() : "No".localized()
                    cell.textLabel?.theme_textColor = Color.title
                    cell.selectionStyle = .none
                default:
                    break
                }
            }
            return cell
        }
        return UITableViewCell()
    }

    // MARK: - Section header view

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        }
        let view = UpdatesSectionHeader(showsButton: section == 0)
        view.configure(with: "Install history for current device".localized())
        view.helpButton.addTarget(self, action: #selector(self.showHelp), for: .touchUpInside)
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        status == nil ? 0 : (60 ~~ 50)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        status == nil
            ? nil
            : section == 0 ? status?.updatedAt : ""
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && status != nil {
            let cachedIPAsVc = CachedIPAs()
            cachedIPAsVc.cachedIPAs = status!.ipas
            navigationController?.pushViewController(cachedIPAsVc, animated: true)
        }
    }

    @objc func showHelp() {
        let message = "API v1.7 provides installation history instead of IPA cache actions. You can review previous installs from this page.".localized()
        let alertController = UIAlertController(title: "Install history for current device".localized(), message: message, preferredStyle: .alert, adaptive: true)
        let okAction = UIAlertAction(title: "OK".localized(), style: .cancel)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
}
