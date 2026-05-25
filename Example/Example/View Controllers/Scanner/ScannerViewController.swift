/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import CoreBluetoothMock
import iOSMcuManagerLibrary

// MARK: - ScannerViewController

final class ScannerViewController: UITableViewController, CBMCentralManagerDelegate, UIPopoverPresentationControllerDelegate, ScannerFilterDelegate {
    
    // MARK: emptyPeripheralsView
    
    private lazy var emptyPeripheralsView: UIView = {
        let footerView = UIStackView()
        footerView.axis = .vertical
        footerView.distribution = .fillProportionally
        footerView.alignment = .center
        footerView.spacing = 12.0
        footerView.frame.size.height = 300
        
        let imageView = UIImageView(image: UIImage(named: "ic_bluetooth_searching_48pt"))
        imageView.contentMode = .scaleAspectFit
        footerView.addArrangedSubview(imageView)
        
        let title = UILabel()
        title.text = "CAN'T SEE YOUR DEVICE?"
        title.textColor = .nordic
        footerView.addArrangedSubview(title)
        
        let content = UILabel()
        content.setContentHuggingPriority(.defaultHigh, for: .vertical)
        content.text = """
        1. Make sure the device is switched on, and connected to a power source.
        
        2. Make sure firmware advertising SMP Server is flashed, and the device is advertising.
          
        3. Check the filter settings.
        By default, the Scanner only shows devices that advertise SMP Service UUID (8D53DC1D-1DB7-4CD3-868B-8A527460AA84).
        """
        content.font = UIFont.preferredFont(forTextStyle: .footnote)
        content.numberOfLines = 0
        content.textColor = .secondary
        footerView.addArrangedSubview(content)
        return footerView
    }()
    
    // MARK: Private Properties
    
    private var pullToRefreshControl: UIRefreshControl!
    private var centralManager: CBMCentralManager!
    private var discoveredPeripherals = [DiscoveredPeripheral]()
    private var filteredPeripherals = [DiscoveredPeripheral]()
    
    private lazy var activityIndicator = UIActivityIndicatorView()
    
    private var filterByName: Bool!
    private var filterByRssi: Bool!
    
    // MARK: onFilterTapped
    
    @objc func onFilterTapped(_ sender: UIBarButtonItem) {
        let filterController = ScannerFilterViewController(style: .plain)
        filterController.preferredContentSize = CGSize(width: 320, height: 98)
        filterController.modalPresentationStyle = .popover
        filterController.delegate = self
        filterController.popoverPresentationController?.delegate = self
        filterController.popoverPresentationController?.permittedArrowDirections = [.any]
        filterController.popoverPresentationController?.barButtonItem = sender
        present(filterController, animated: true)
    }
    
    // MARK: onInfoTapped
    
    @objc func onInfoTapped(_ sender: UIBarButtonItem) {
        let rootViewController = navigationController as? RootViewController
        rootViewController?.showIntro(animated: true)
    }
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Device Manager"
        
        centralManager = CBMCentralManagerFactory.instance(delegate: self, queue: .main)
        centralManager.delegate = self
        
        // Default to true to filter devices by name
        filterByName = UserDefaults.standard.object(forKey: "filterByName") != nil ? UserDefaults.standard.bool(forKey: "filterByName") : true
        filterByRssi = UserDefaults.standard.bool(forKey: "filterByRssi")
        
        tableView.register(ScannerTableViewCell.self, forCellReuseIdentifier: ScannerTableViewCell.reuseIdentifier)
        
        #if targetEnvironment(simulator)
        CBMCentralManagerMock.simulateInitialState(.poweredOn)
        let uart = UART()
        CBMCentralManagerMock.simulatePeripherals([
            uart.spec,
        ])
        #endif
    }
    
    // MARK: viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        discoveredPeripherals.removeAll()
        tableView.reloadData()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "switch.2"), style: .plain, target: self, action: #selector(onFilterTapped(_:)))
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        let activityBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        let infoBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "info"), style: .plain, target: self, action: #selector(onInfoTapped(_:)))
        navigationItem.rightBarButtonItems = [infoBarButtonItem, activityBarButtonItem]
        for rightBarButtonItem in navigationItem.rightBarButtonItems ?? [] {
            rightBarButtonItem.tintColor = .white
        }
        
        guard pullToRefreshControl == nil else { return }
        pullToRefreshControl = UIRefreshControl()
        pullToRefreshControl.addTarget(self, action: #selector(onPullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = pullToRefreshControl
    }
    
    // MARK: viewDidAppear
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if centralManager.state == .poweredOn {
            startScanner()
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // This will force the Filter ViewController
        // to be displayed as a popover on iPhones.
        return .none
    }
    
    // MARK: Pull-to-refresh
    
    @objc private func onPullToRefresh(_ sender: Any?) {
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        discoveredPeripherals.removeAll()
        filteredPeripherals.removeAll()
        tableView.reloadData()
        pullToRefreshControl.endRefreshing()
        startScanner()
    }
    
    // MARK: Filter delegate
    
    func filterSettingsDidChange(filterByName: Bool, filterByRssi: Bool) {
        self.filterByName = filterByName
        self.filterByRssi = filterByRssi
        UserDefaults.standard.set(filterByName, forKey: "filterByName")
        UserDefaults.standard.set(filterByRssi, forKey: "filterByRssi")
        
        filteredPeripherals.removeAll()
        for peripheral in discoveredPeripherals {
            if matchesFilters(peripheral) {
                filteredPeripherals.append(peripheral)
            }
        }
        tableView.reloadData()
    }
    
    // MARK: Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredPeripherals.count > 0 {
            hideEmptyPeripheralsView()
        } else {
            showEmptyPeripheralsView()
        }
        return filteredPeripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ScannerTableViewCell! = tableView.dequeueReusableCell(withIdentifier: ScannerTableViewCell.reuseIdentifier, for: indexPath) as? ScannerTableViewCell
        cell.setupViewWithPeripheral(filteredPeripherals[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        centralManager.stopScan()
        activityIndicator.stopAnimating()
        
        let baseViewController = BaseViewController(filteredPeripherals[indexPath.row])
        navigationController?.pushViewController(baseViewController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == 0 else { return nil }
        return "   Scanner"
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 0 else { return nil }
        return "   ⓘ You can Pull-to-refresh this list."
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManager(_ central: CBMCentralManager, didDiscover peripheral: CBMPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Find peripheral among already discovered ones, or create a new
        // object if it is a new one.
        var discoveredPeripheral: DiscoveredPeripheral! = discoveredPeripherals.first(where: {
            $0.basePeripheral.identifier == peripheral.identifier
        })
        if discoveredPeripheral == nil {
            discoveredPeripheral = DiscoveredPeripheral(peripheral)
            discoveredPeripherals.append(discoveredPeripheral)
        }
        
        // Update the object with new values.
        discoveredPeripheral.update(withAdvertisementData: advertisementData, andRSSI: RSSI)
        
        // If the device is already on the filtered list, update it.
        // It will be shown even if the advertising packet is no longer
        // matching the filter. We don't want any blinking on the device list.
        if let index = filteredPeripherals.firstIndex(of: discoveredPeripheral) {
            // Update the cell views directly, without refreshing the
            // whole table.
            if let cell = tableView.cellForRow(at: [0, index]) as? ScannerTableViewCell {
                cell.peripheralUpdatedAdvertisementData(discoveredPeripheral)
            }
        } else {
            // Check if the peripheral matches the current filters.
            if matchesFilters(discoveredPeripheral) {
                filteredPeripherals.append(discoveredPeripheral)
                tableView.reloadData()
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBMCentralManager) {
        if central.state != .poweredOn {
            print("Central is not powered on")
            activityIndicator.stopAnimating()
        } else {
            startScanner()
        }
    }
    
    // MARK: Private helper methods
    
    private func startScanner() {
        activityIndicator.startAnimating()
        let hidService: CBMUUID! = CBMUUID(string: "1812")
        let defaultTransportConfiguration = DefaultTransportConfiguration()
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [defaultTransportConfiguration.serviceUUID, hidService])
        for peripheral in connectedPeripherals {
            var advertisementData = [String: Any]()
            advertisementData[CBMAdvertisementDataLocalNameKey] = peripheral.name ?? ""
            centralManager(centralManager, didDiscover: peripheral, advertisementData: advertisementData, rssi: -127)
        }
        centralManager.scanForPeripherals(withServices: nil, options: [CBMCentralManagerScanOptionAllowDuplicatesKey : true])
    }
    
    /// Shows the No Peripherals view.
    private func showEmptyPeripheralsView() {
        guard tableView.tableFooterView == nil else { return }
        UIView.animate(withDuration: 0.5, animations: { [unowned self] in
            self.tableView.tableFooterView = emptyPeripheralsView
        })
    }
    
    /// Hides the No Peripherals view. This method should be
    /// called when a first peripheral was found.
    private func hideEmptyPeripheralsView() {
        guard tableView.tableFooterView != nil else { return }
        UIView.animate(withDuration: 0.5, animations: { [unowned self] in
            self.tableView.tableFooterView = nil
        })
    }
    
    /// Returns true if the discovered peripheral matches
    /// current filter settings.
    ///
    /// - parameter discoveredPeripheral: A peripheral to check.
    /// - returns: True, if the peripheral matches the filter,
    ///   false otherwise.
    private func matchesFilters(_ discoveredPeripheral: DiscoveredPeripheral) -> Bool {
        // Filter by name if the name filter switch is on
        if filterByName {
            // Only show devices with a name (not "N/A" or empty)
            if discoveredPeripheral.advertisedName.isEmpty || discoveredPeripheral.advertisedName == "N/A" {
                return false
            }
        }
        if filterByRssi && discoveredPeripheral.highestRSSI.decimalValue < -50 {
            return false
        }
        return true
    }
}
