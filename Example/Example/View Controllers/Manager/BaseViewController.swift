/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import CoreBluetooth
import iOSMcuManagerLibrary
import iOSOtaLibrary

// MARK: - BaseViewController

final class BaseViewController: UITabBarController {
    
    // MARK: Properties
    
    weak var deviceStatusDelegate: DeviceStatusManager.Delegate? {
        didSet {
            if let peripheralState {
                deviceStatusDelegate?.transportStateDidChange(peripheralState)
            }
            if let statusInfo {
                deviceStatusDelegate?.statusInfoDidChange(statusInfo)
            }
            if let otaStatus {
                deviceStatusDelegate?.otaStatusChanged(otaStatus)
            }
            if let observabilityStatusInfo {
                deviceStatusDelegate?.observabilityStatusChanged(observabilityStatusInfo)
            }
        }
    }
    
    /**
     Shared ``McuMgrTransport`` for subclasses to use.
     */
    var transport: McuMgrTransport!
    
    var peripheral: DiscoveredPeripheral!
    
    // MARK: init
    
    init(_ peripheral: DiscoveredPeripheral) {
        let bleTransport = McuMgrBleTransport(peripheral.basePeripheral.identifier)
        bleTransport.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
        transport = bleTransport
        self.peripheral = peripheral
        super.init(nibName: nil, bundle: nil)
        
        (transport as? McuMgrBleTransport)?.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Private Properties
    
    private var deviceStatusManager: DeviceStatusManager?
    private var observabilityStatusManager: ObservabilityStatusManager?
    
    private var deviceInfoRequested: Bool = false
    private var statusInfoCallback: (() -> ())?
    
    private var peripheralState: PeripheralState? {
        didSet {
            guard let peripheralState else { return }
            deviceStatusDelegate?.transportStateDidChange(peripheralState)
        }
    }
    
    private var statusInfo: DeviceStatusInfo? {
        didSet {
            guard let statusInfo else { return }
            deviceStatusDelegate?.statusInfoDidChange(statusInfo)
        }
    }
    
    private var otaStatus: OTAStatus? {
        didSet {
            guard let otaStatus else { return }
            deviceStatusDelegate?.otaStatusChanged(otaStatus)
        }
    }
    
    private var observabilityStatusInfo: ObservabilityStatusInfo? {
        didSet {
            guard let observabilityStatusInfo else { return }
            deviceStatusDelegate?.observabilityStatusChanged(observabilityStatusInfo)
        }
    }
    
    // MARK: viewDidLoad()
    
    override func viewDidLoad() {
        title = peripheral.advertisedName
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.dynamicColor(light: .systemBackground, dark: .secondarySystemBackground)
           
            tabBar.tintColor = .nordic
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.tintColor = .nordic
            tabBar.isTranslucent = false
        }
        
        setupViewControllers()
    }
    
    // MARK: setupViewControllers()
    
    private func setupViewControllers() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        let deviceViewController = DeviceController(style: .grouped)
        deviceViewController.tabBarItem = UITabBarItem(title: "Device", image: UIImage(systemName: "cpu"), selectedImage: nil)
        
        let imageViewController: ImageController! = storyboard.instantiateViewController(identifier: "imageVC")
        imageViewController.tabBarItem = UITabBarItem(title: "Image", image: UIImage(systemName: "arrow.down.to.line"), selectedImage: nil)
        
        let filesViewController = FilesController(style: .grouped)
        filesViewController.tabBarItem = UITabBarItem(title: "Files", image: UIImage(systemName: "document"), selectedImage: nil)
        
        let diagnosticsViewController = DiagnosticsController(style: .grouped)
        diagnosticsViewController.tabBarItem = UITabBarItem(title: "Diagnostics", image: UIImage(systemName: "chart.bar.horizontal.page"), selectedImage: nil)
        
        viewControllers = [deviceViewController, imageViewController, filesViewController, diagnosticsViewController]
    }
    
    // MARK: viewWillDisappear()
    
    override func viewWillDisappear(_ animated: Bool) {
        disconnect()
    }
    
    // MARK: disconnect()
    
    func disconnect() {
        stopObservability()
        transport?.close()
    }
}

// MARK: - DeviceStatusRow

enum DeviceStatusRow: Int, RawRepresentable, CaseIterable, CustomStringConvertible {
    case smpService
    case mcuMgrParameters
    case bootloaderName
    case bootloaderMode
    case bootloaderSlot
    case kernel
    case otaStatus
    case observabilityStatus
    
    var description: String {
        switch self {
        case .smpService:
            return "SMP Service"
        case .mcuMgrParameters:
            return "Buffer Details"
        case .bootloaderName:
            return "Bootloader Name"
        case .bootloaderMode:
            return "Bootloader Mode"
        case .bootloaderSlot:
            return "Bootlaoder Slot"
        case .kernel:
            return "Kernel"
        case .otaStatus:
            return "OTA"
        case .observabilityStatus:
            return "Observability"
        }
    }
}

// MARK: - Device Status

extension BaseViewController {
    
    // MARK: tableView(_:cellForRowAt:)
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = DeviceStatusRow(rawValue: indexPath.row)
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "DeviceStatusRow")
        cell.selectionStyle = .none
        cell.textLabel?.text = row?.description
        cell.detailTextLabel?.text = "UNKNOWN"
        cell.accessoryType = .detailButton
        cell.tintColor = .nordic
        update(cell, asDeviceStatusRow: row)
        return cell
    }
    
    // MARK: update(_:asDeviceStatusRow:)
    
    func update(_ cell: UITableViewCell, asDeviceStatusRow row: DeviceStatusRow?) {
        switch row {
        case .smpService:
            cell.detailTextLabel?.text = peripheralState?.description
        case .mcuMgrParameters:
            if let buffers = statusInfo?.bufferCount, let size = statusInfo?.bufferSize {
                cell.detailTextLabel?.text = "\(buffers) x \(size) bytes"
            } else {
                cell.detailTextLabel?.text = "UNKNOWN"
            }
        case .bootloaderName:
            guard let bootloader = statusInfo?.bootloader, bootloader != .unknown else {
                cell.detailTextLabel?.text = "UNKNOWN"
                break
            }
            cell.detailTextLabel?.text = bootloader.description
        case .bootloaderMode:
            if let mode = statusInfo?.bootloaderMode {
                cell.detailTextLabel?.text = mode.description
            } else {
                cell.detailTextLabel?.text = "UNKNOWN"
            }
        case .bootloaderSlot:
            if let slot = statusInfo?.bootloaderSlot {
                cell.detailTextLabel?.text = "\(slot)"
            } else {
                cell.detailTextLabel?.text = "UNKNOWN"
            }
        case .kernel:
            if let appInfo = statusInfo?.appInfoOutput {
                cell.detailTextLabel?.text = appInfo
            } else {
                cell.detailTextLabel?.text = "UNKNOWN"
            }
        case .otaStatus:
            if let otaStatus {
                cell.detailTextLabel?.text = otaStatus.description
            } else {
                cell.detailTextLabel?.text = "UNKNOWN"
            }
        case .observabilityStatus:
            if let observabilityStatusInfo {
                cell.detailTextLabel?.text = observabilityStatusInfo.status.description
            } else {
                cell.detailTextLabel?.text = "UNKNOWN"
            }
        case .none:
            break
        }
    }
    
    // MARK: onDeviceStatusReady(_:)
    
    func onDeviceStatusReady(_ callback: @escaping () -> Void) {
        statusInfoCallback = callback
        guard !deviceInfoRequested else {
            onDeviceStatusFinished()
            return
        }
        
        if deviceStatusManager == nil {
            deviceStatusManager = DeviceStatusManager(
                transport, logDelegate: UIApplication.shared.delegate as? McuMgrLogDelegate
            )
        }
        guard let deviceStatusManager else { return }
        
        Task { @MainActor in
            statusInfo = await deviceStatusManager.requestStatusInfo()
            
            guard let peripheral = peripheral?.basePeripheral else {
                onDeviceStatusFinished()
                return
            }
            otaStatus = await deviceStatusManager.requestOTAStatus(for: peripheral.identifier)
            onDeviceStatusFinished()
        }
    }
    
    // MARK: onDeviceStatusReady() async
    
    func onDeviceStatusReady() async {
        // Clear because we don't want to trigger the delegate-based callback.
        statusInfoCallback = nil
        guard !deviceInfoRequested else {
            onDeviceStatusFinished()
            return
        }
        
        if deviceStatusManager == nil {
            deviceStatusManager = DeviceStatusManager(
                transport, logDelegate: UIApplication.shared.delegate as? McuMgrLogDelegate
            )
        }
        
        guard let deviceStatusManager else { return }
        statusInfo = await deviceStatusManager.requestStatusInfo()
        
        guard let peripheral = peripheral?.basePeripheral else {
            onDeviceStatusFinished()
            return
        }
        otaStatus = await deviceStatusManager.requestOTAStatus(for: peripheral.identifier)
        onDeviceStatusFinished()
    }
    
    // MARK: onDeviceStatusFinished
    
    private func onDeviceStatusFinished() {
        guard let statusInfoCallback else { return }
        statusInfoCallback()
        deviceInfoRequested = true
        self.statusInfoCallback = nil
    }
}
 
// MARK: - Observability

extension BaseViewController {
        
    func observabilityButtonTapped() {
        guard let observabilityStatusManager else {
            onDeviceStatusReady {} // Full Reconnection
            return
        }
        
        switch observabilityStatusInfo?.status {
        case .receivedEvent(let event):
            switch event {
            case .online(false):
                do {
                    try observabilityStatusManager.resumePendingUploads()
                } catch {
                    print("\(#function): RETRY Error \(error.localizedDescription)")
                }
            default:
                disconnect()
            }
        default:
            disconnect()
        }
    }
}

// MARK: - onDeviceStatusAccessoryTapped

extension BaseViewController {
    
    func onDeviceStatusAccessoryTapped(at indexPath: IndexPath) {
        guard let statusRow = DeviceStatusRow(rawValue: indexPath.row) else { return }
        let helpDialogAlertController = UIAlertController(title: "\(statusRow) Help", message: nil, preferredStyle: .alert)
        switch statusRow {
        case .smpService:
            helpDialogAlertController.message = "\nReports the status of the SMP Service connection to the device."
        case .mcuMgrParameters:
            helpDialogAlertController.message = "\nNumber of MCU Manager buffers and their size. Requires MCU Mgr Parameters command in OS Group."
        case .bootloaderName:
            helpDialogAlertController.message = "\nName of the Bootloader. Requires Bootloader Info command in OS Group."
        case .bootloaderMode:
            helpDialogAlertController.message = "\nMode of the MCUboot Bootloader."
        case .bootloaderSlot:
            helpDialogAlertController.message = "\nAlso known as \"Active B0 Slot\"; slot from which nRF Secure Immutable Bootloader (NSIB), also known as B0, booted the Application."
        case .kernel:
            helpDialogAlertController.message = "\nKernel name and version. Requires Application Info command in OS Group."
        case .otaStatus:
            helpDialogAlertController.message = "\nReports whether Firmware Over-the-Air (OTA) Updates via nRF Cloud are supported in this device."
            if let url = URL(string: "https://docs.nordicsemi.com/bundle/nrf-cloud/page/Devices/FirmwareUpdate/FOTAOverview.html") {
                helpDialogAlertController.addAction(UIAlertAction(title: "OTA Documentation", style: .default, handler: { _ in
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }))
            }
        case .observabilityStatus:
            helpDialogAlertController.message = "\nReports whether nRF Cloud Observability is supported and active for this device. nRF Cloud Observability allows collecting and analysing on-device metrics such as coredumps and logs from devices in your fleet. Useful for debugging bugs & crashes."
            if let url = URL(string: "https://docs.nordicsemi.com/bundle/nrf-cloud/page/index.html") {
                helpDialogAlertController.addAction(UIAlertAction(title: "Discover nRF Cloud", style: .default, handler: { _ in
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }))
            }
        }
        present(helpDialogAlertController, addingCancelAction: true, cancelActionTitle: "OK")
    }
}

// MARK: - Present Dialog

extension BaseViewController {
    
    func present(_ alertViewController: UIAlertController,
                 addingCancelAction addCancelAction: Bool = false,
                 cancelActionTitle: String = "Cancel") {
        if addCancelAction {
            alertViewController.addAction(UIAlertAction(title: cancelActionTitle, style: .cancel))
        }
        
        // If the device is an ipad set the popover presentation controller
        if let presenter = alertViewController.popoverPresentationController {
            presenter.sourceView = self.view
            presenter.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            presenter.permittedArrowDirections = []
        }
        present(alertViewController, animated: true)
    }
}

// MARK: - Observability

extension BaseViewController {
    
    func startObservability(for peripheral: CBPeripheral) {
        guard observabilityStatusManager == nil else {
            return // Already in Progress.
        }
        let peripheralUUID = peripheral.identifier
        Task { @MainActor in
            observabilityStatusManager = ObservabilityStatusManager(peripheralIdentifier: peripheralUUID)
            guard let stream = observabilityStatusManager?.startObservabilityTask() else { return }
            print("\(#function): STARTED Listening to \(peripheralUUID) Observability Events.")
            for await statusInfo in stream {
                observabilityStatusInfo = statusInfo
            }
            print("\(#function): STOPPED Listening to \(peripheralUUID) Observability Events.")
            var connectionClosedStatus = observabilityStatusInfo
            connectionClosedStatus?.updatedStatus(.connectionClosed)
            observabilityStatusInfo = connectionClosedStatus
        }
    }
    
    func stopObservability() {
        observabilityStatusManager?.stopObservabilityManagerAndTask()
        observabilityStatusManager = nil
    }
}

// MARK: - PeripheralDelegate

extension BaseViewController: PeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didChangeStateTo state: PeripheralState) {
        peripheralState = state
        switch state {
        case .connecting:
            // Don't wait for .connected because McuMgrBleTransport only sends 'connected'
            // if SMP Service is found. Observability might still work because it relies
            // on MDS Service Instead.
            startObservability(for: peripheral)
        case .disconnecting, .disconnected:
            // Set to false, because a DFU update might change things if that's what happened.
            deviceInfoRequested = false
        default:
            // Nothing to do here.
            break
        }
    }
}
