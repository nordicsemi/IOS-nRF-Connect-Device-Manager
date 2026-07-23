/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import iOSMcuManagerLibrary
import iOSOtaLibrary

// MARK: - ImageController

final class ImageController: UITableViewController, ExtendedMcuMgrViewController {
    
    // MARK: UI Properties
    
    internal lazy var uploadFilenameLabel: UILabel = {
        let label = UILabel()
        label.text = "No file selected"
        label.textColor = .secondary
        label.font = .preferredFont(forTextStyle: .callout)
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    internal var uploadSelectFile: UIButton?
    internal var uploadCheckForUpdates: UIButton?
    internal var uploadEraseAppSettingsSwitch: UISwitch?
    internal var uploadStateLabel: UILabel?
    
    internal lazy var uploadSwapButton: UIButton = {
        let button = UIButton()
        button.setTitle("Swap", for: .normal)
        button.setTitleColor(.nordic, for: .normal)
        button.setTitleColor(.nordic.withAlphaComponent(0.5), for: .disabled)
        button.addTarget(self, action: #selector(setSwapTime), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    internal lazy var uploadBuffersButton: UIButton = {
        let button = UIButton()
        button.setTitle("Buffers", for: .normal)
        button.setTitleColor(.nordic, for: .normal)
        button.setTitleColor(.nordic.withAlphaComponent(0.5), for: .disabled)
        button.addTarget(self, action: #selector(setPipelineDepth), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    internal lazy var uploadAlignmentButton: UIButton = {
        let button = UIButton()
        button.setTitle("Alignment", for: .normal)
        button.setTitleColor(.nordic, for: .normal)
        button.setTitleColor(.nordic.withAlphaComponent(0.5), for: .disabled)
        button.addTarget(self, action: #selector(setByteAlignment), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    internal lazy var uploadActionButton: UIButton = {
        let button = UIButton()
        button.setTitle("Start", for: .normal)
        button.setTitleColor(.nordic, for: .normal)
        button.setTitleColor(.nordic.withAlphaComponent(0.5), for: .disabled)
        button.addTarget(self, action: #selector(uploadAction), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    internal lazy var uploadCancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.setTitleColor(.red.withAlphaComponent(0.5), for: .disabled)
        button.addTarget(self, action: #selector(uploadCancel), for: .touchUpInside)
        if #available(iOS 14.0, *) {
            button.role = .destructive
        }
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    internal lazy var uploadSpeedLabel: UILabel = {
        let label = UILabel()
        label.text = "SPEED"
        label.textColor = .secondary
        label.font = .preferredFont(forTextStyle: .footnote)
        label.isHidden = true
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    internal lazy var uploadProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progress = 0.0
        progressView.tintColor = .nordic
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    internal lazy var imagesTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap READ button to download image slots information."
        label.textColor = .secondary
        label.font = .preferredFont(forTextStyle: .callout)
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    internal var imagesReadButton: UIButton?
    internal var imagesTestButton: UIButton?
    internal var imagesConfirmButton: UIButton?
    internal var imagesEraseButton: UIButton?
    
    internal var settingsEraseButton: UIButton?
    
    internal var resetFwLoaderSwitch: UISwitch?
    internal var resetAdvName: UITextField?
    internal var resetButton: UIButton?
    
    // MARK: Logic Properties
    
    internal var advancedMode: Bool = false
    internal var fwLoaderAdvName: String?
    internal var fwLoaderSwitchValue: Bool = false
    
    internal var fileURL: URL?
    internal var fileError: (any Error)?
    internal var package: McuMgrPackage?
    
    // MARK: Manager(s)
    
    internal var dfuManager: FirmwareUpgradeManager!
    internal var basicManager: BasicManager!
    internal var imageManager: ImageManager!
    internal var defaultManager: DefaultManager!
    internal var settingsManager: SettingsManager!
    internal var suitManager: SuitManager!
    
    var transport: McuMgrTransport! {
        didSet {
            dfuManager = FirmwareUpgradeManager(transport: transport, delegate: self)
            dfuManager.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
            basicManager = BasicManager(transport: transport)
            basicManager.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
            imageManager = ImageManager(transport: transport)
            imageManager.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
            defaultManager = DefaultManager(transport: transport)
            defaultManager.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
            settingsManager = SettingsManager(transport: transport)
            settingsManager.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
            suitManager = SuitManager(transport: transport)
            suitManager.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
        }
    }
    
    // nRF52840 requires ~ 10 seconds for swapping images.
    // Adjust this parameter for your device.
    internal var dfuManagerConfiguration = FirmwareUpgradeConfiguration(
        estimatedSwapTime: 10.0, eraseAppSettings: false, pipelineDepth: 3, byteAlignment: .fourByte)
    internal var dfuState: FirmwareUpgradeState?
    internal var initialBytes: Int = 0
    internal var uploadImageSize: Int!
    internal var uploadTimestamp: Date!
    
    internal var bootloader: BootloaderInfoResponse.Bootloader?
    internal var readImagesResponse: McuMgrImageStateResponse?
    
    internal var otaManager: OTAManager?
    internal var otaStatus: OTAStatus?
    
    // MARK: UIViewController
    
    override func viewDidAppear(_ animated: Bool) {
        showModeSwitch()
        restoreBasicSettings()
        
        let baseController: BaseViewController! = parent as? BaseViewController
        baseController.deviceStatusDelegate = self
        transport = baseController.transport
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController?.navigationItem.rightBarButtonItem = nil
    }
    
    // MARK: Handling Basic / Advanced mode
    
    @objc func modeSwitched() {
        showModeSwitch(toggle: true)
        DispatchQueue.main.async { [unowned self] in
            tableView.reloadData()
        }
    }
    
    private func showModeSwitch(toggle: Bool = false) {
        if toggle {
            advancedMode.toggle()
        }
        
        let action = advancedMode ? "Basic" : "Advanced"
        let navItem = tabBarController?.navigationItem
        navItem?.rightBarButtonItem = UIBarButtonItem(title: action, style: .plain,
                                                     target: self, action: #selector(modeSwitched))
    }
    
    // MARK: UITableView
    
    enum Section: Int, RawRepresentable, CaseIterable {
        case deviceStatus
        case sharedUpload
        case advancedImages
        case advancedSettings
        case advancedReset
        
        var title: String {
            switch self {
            case .deviceStatus:
                return "Device Status"
            case .sharedUpload:
                return "Upload"
            case .advancedImages:
                return "Images"
            case .advancedSettings:
                return "Settings"
            case .advancedReset:
                return "Reset"
            }
        }
    }
    
    enum SharedUploadSectionRow: Int, RawRepresentable, CaseIterable {
        case selectFile
        case checkOtaUpdate
        case fileSize
        case fileHash
        case fileState
        case eraseAppSettings
        case swapTime
        case numberOfBuffers
        case byteAlignment
        case progressBar
        case uploadButtons
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return advancedMode ? Section.allCases.count : 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .sharedUpload:
            return advancedMode ? "Upload Only" : "Upgrade"
        default:
            return section.title
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .deviceStatus:
            return DeviceStatusRow.allCases.count
        case .sharedUpload:
            return SharedUploadSectionRow.allCases.count
        case .advancedImages:
            return ImagesSectionRow.allCases.count
        case .advancedSettings:
            return SettingsSectionRow.allCases.count
        case .advancedReset:
            return ResetSectionRow.allCases.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)
        switch section {
        case .deviceStatus:
            return (parent as? BaseViewController)?.tableView(tableView, cellForRowAt: indexPath)
                ?? UITableViewCell()
        case .sharedUpload:
            return sharedUploadSectionCell(for: SharedUploadSectionRow(rawValue: indexPath.row))
        case .advancedImages:
            return imagesSectionCell(for: ImagesSectionRow(rawValue: indexPath.row))
        case .advancedSettings:
            return settingsSectionCell(for: SettingsSectionRow(rawValue: indexPath.row))
        case .advancedReset:
            return resetSectionCell(for: ResetSectionRow(rawValue: indexPath.row))
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .sharedUpload:
            // Trick to update Section Buttons that are not always visible.
            updateActionableButtonsState(for: .none)
            fallthrough
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)
        switch section {
        case .deviceStatus:
            (parent as? BaseViewController)?.onDeviceStatusAccessoryTapped(at: indexPath)
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - DeviceStatusDelegate

extension ImageController: DeviceStatusManager.Delegate {
    
    func transportStateDidChange(_ state: PeripheralState) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
    
    func statusInfoDidChange(_ info: DeviceStatusInfo) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
    
    func otaStatusChanged(_ status: OTAStatus) {
        otaStatus = status
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
    
    func observabilityStatusChanged(_ statusInfo: ObservabilityStatusInfo) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
}

// MARK: - UIDocumentPickerDelegate

extension ImageController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentAt url: URL) {
        select(url)
    }
    
    // MARK: Internal
    
    func select(_ url: URL) {
        fileURL = nil
        fileError = nil
        package = nil
        
        Task {
            switch await parseAsMcuMgrPackage(url) {
            case .success(let package):
                fileURL = url
                self.package = package
                tableView.reloadSections(IndexSet([Section.sharedUpload.rawValue]), with: .none)
            case .failure(let error):
                onParseError(error, for: url)
            }
        }
    }
    
    @concurrent
    func parseAsMcuMgrPackage(_ url: URL) async -> Result<McuMgrPackage, Error> {
        do {
            let package = try McuMgrPackage(from: url)
            return .success(package)
        } catch {
            return .failure(error)
        }
    }
    
    func onParseError(_ error: Error, for url: URL) {
        self.package = nil
        self.fileError = error
        tableView.reloadSections(IndexSet([Section.sharedUpload.rawValue]), with: .none)
    }
}

// MARK: - UserDefaults Keys

internal extension ImageController {
    
    enum Key: String, RawRepresentable {
        case swapTime = "basic_SwapTime"
        case pipelineDepth = "basic_PipelineDepth"
        case byteAlignment = "basic_ByteAlignment"
        case eraseAppSettings = "basic_EraseSettings"
        
        case chunkSize = "advanced_ChunkSize"
    }
    
    private func restoreBasicSettings() {
        if UserDefaults.standard.object(forKey: Key.swapTime.rawValue) != nil {
            let swapTime = UserDefaults.standard.integer(forKey: Key.swapTime.rawValue)
            updateEstimatedSwapTime(to: swapTime, updatingUserDefaults: false)
        }
        
        if UserDefaults.standard.object(forKey: Key.pipelineDepth.rawValue) != nil {
            let pipelineDepth = UserDefaults.standard.integer(forKey: Key.pipelineDepth.rawValue)
            updatePipelineDepth(to: pipelineDepth + 1, updatingUserDefaults: false)
        }
        
        if UserDefaults.standard.object(forKey: Key.byteAlignment.rawValue) != nil {
            let rawByte = UserDefaults.standard.integer(forKey: Key.byteAlignment.rawValue)
            if let byteAlignment = ImageUploadAlignment(rawValue: UInt64(rawByte)) {
                updateByteAlignment(to: byteAlignment, updatingUserDefaults: false)
            }
        }
        
        if UserDefaults.standard.object(forKey: Key.eraseAppSettings.rawValue) != nil {
            let eraseAppSettings = UserDefaults.standard.bool(forKey: Key.eraseAppSettings.rawValue)
            updateEraseApplicationSettings(to: eraseAppSettings, updatingUserDefaults: false)
        }
    }
}
