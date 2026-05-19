/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit

// MARK: - ScannerFilterDelegate

protocol ScannerFilterDelegate: AnyObject {
    /// Called when user modifies the filter.
    func filterSettingsDidChange(filterByName: Bool, filterByRssi: Bool)
}

// MARK: - ScannerFilterViewController

final class ScannerFilterViewController: UITableViewController {
    
    private var filterByNameEnabled: Bool!
    private var filterByRssiEnabled: Bool!
    weak var delegate: ScannerFilterDelegate?
    
    // MARK: selectors
    
    @objc func onFilterByNameChanged(_ sender: UISwitch) {
        filterByNameEnabled = sender.isOn
        delegate?.filterSettingsDidChange(
            filterByName: filterByNameEnabled,
            filterByRssi: filterByRssiEnabled)
    }
    
    @objc func onFilterByRSSIChanged(_ sender: UISwitch) {
        filterByRssiEnabled = sender.isOn
        delegate?.filterSettingsDidChange(
            filterByName: filterByNameEnabled,
            filterByRssi: filterByRssiEnabled)
    }
    
    // MARK: viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        filterByNameEnabled = UserDefaults.standard.object(forKey: "filterByName") != nil ? UserDefaults.standard.bool(forKey: "filterByName") : true
        filterByRssiEnabled = UserDefaults.standard.bool(forKey: "filterByRssi")
    }
    
    // MARK: Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.accessoryView = UISwitch()
        (cell.accessoryView as? UISwitch)?.onTintColor = .nordic
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Show only named devices"
            (cell.accessoryView as? UISwitch)?.isOn = filterByNameEnabled
            (cell.accessoryView as? UISwitch)?.addTarget(self, action: #selector(onFilterByNameChanged(_:)), for: .valueChanged)
        case 1:
            cell.textLabel?.text = "Only nearby devices"
            (cell.accessoryView as? UISwitch)?.isOn = filterByRssiEnabled
            (cell.accessoryView as? UISwitch)?.addTarget(self, action: #selector(onFilterByRSSIChanged(_:)), for: .valueChanged)
        default:
            break
        }
        return cell
    }
}
