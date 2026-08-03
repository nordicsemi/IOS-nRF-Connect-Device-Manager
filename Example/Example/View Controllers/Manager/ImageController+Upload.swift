//
//  ImageController+Basic.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 08/06/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import iOSMcuManagerLibrary
import iOSOtaLibrary

extension ImageController {
    
    // MARK: sharedUploadSectionCell(for:)
    
    func sharedUploadSectionCell(for row: SharedUploadSectionRow?) -> UITableViewCell {
        switch row {
        case .selectFile:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "selectFile")
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.size.width, bottom: 0, right: 0)
            
            if uploadFilenameLabel.superview != nil {
                uploadFilenameLabel.removeFromSuperview()
            }
            cell.contentView.addSubview(uploadFilenameLabel)
            
            if let fileURL {
                uploadFilenameLabel.text = fileURL.lastPathComponent
                uploadFilenameLabel.textColor = .primary
            } else if let fileError {
                uploadFilenameLabel.text = fileError.localizedDescription
                uploadFilenameLabel.textColor = .systemRed
            } else {
                uploadFilenameLabel.text = "No file selected."
                uploadFilenameLabel.textColor = .secondary
            }
            
            let selectFileButton = UIButton()
            selectFileButton.setTitle("Select File", for: .normal)
            selectFileButton.setTitleColor(.nordic, for: .normal)
            selectFileButton.setTitleColor(.secondary, for: .disabled)
            selectFileButton.addTarget(self, action: #selector(selectFirmware), for: .touchUpInside)
            selectFileButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            selectFileButton.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(selectFileButton)
            uploadSelectFile = selectFileButton
            
            NSLayoutConstraint.activate([
                selectFileButton.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                selectFileButton.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: uploadFilenameLabel.trailingAnchor, multiplier: 1.0),
                selectFileButton.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                
                uploadFilenameLabel.firstBaselineAnchor.constraint(equalTo: selectFileButton.firstBaselineAnchor),
                uploadFilenameLabel.leadingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.leadingAnchor, constant: 14.0),
                
                cell.contentView.bottomAnchor.constraint(equalTo: selectFileButton.bottomAnchor, constant: -4.0)
            ])
            
            return cell
        case .checkOtaUpdate:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "otaUpdate")
            cell.selectionStyle = .none
            
            let checkOtaButton = UIButton()
            checkOtaButton.setTitle("Check for Updates", for: .normal)
            checkOtaButton.setTitleColor(.nordic, for: .normal)
            checkOtaButton.setTitleColor(.secondary, for: .disabled)
            checkOtaButton.addTarget(self, action: #selector(checkForUpdates), for: .touchUpInside)
            checkOtaButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            checkOtaButton.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(checkOtaButton)
            uploadCheckForUpdates = checkOtaButton
            
            let otaLabel = UILabel()
            otaLabel.text = "nRF Cloud OTA"
            otaLabel.textColor = .secondary
            otaLabel.font = .preferredFont(forTextStyle: .caption1)
            otaLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(otaLabel)
            
            NSLayoutConstraint.activate([
                checkOtaButton.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                checkOtaButton.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                
                otaLabel.firstBaselineAnchor.constraint(equalTo: checkOtaButton.firstBaselineAnchor),
                otaLabel.trailingAnchor.constraint(equalTo: checkOtaButton.leadingAnchor, constant: -8.0),
                
                cell.contentView.bottomAnchor.constraint(equalTo: checkOtaButton.bottomAnchor, constant: 8.0)
            ])
            
            return cell
        case .fileSize, .fileHash:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "sharedFileInfo")
            cell.selectionStyle = .none
            
            let label = UILabel(frame: .zero)
            label.font = .preferredFont(forTextStyle: .callout)
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.textColor = .primary
            label.numberOfLines = 1
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(label)
            
            let multiLine = UILabel(frame: .zero)
            multiLine.textAlignment = .right
            multiLine.textColor = .secondary
            multiLine.numberOfLines = 0
            multiLine.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(multiLine)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: cell.contentView.topAnchor, multiplier: 1.0),
                label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16.0),
                
                multiLine.firstBaselineAnchor.constraint(equalTo: label.firstBaselineAnchor),
                multiLine.leadingAnchor.constraint(equalToSystemSpacingAfter: label.trailingAnchor, multiplier: 1.0),
                multiLine.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -14.0),
                
                cell.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: multiLine.bottomAnchor, multiplier: 1.0)
            ])
            
            switch row {
            case .fileSize:
                label.text = "Size"
                if let package {
                    multiLine.numberOfLines = 0
                    multiLine.text = package.sizeString()
                } else {
                    multiLine.numberOfLines = 1
                    multiLine.text = "N/A"
                }
            case .fileHash:
                label.text = "Hash"
                if let envelope = package?.envelope {
                    multiLine.text = envelope.digest.hashString()
                    multiLine.numberOfLines = 0
                } else if let package {
                    multiLine.text = package.hashString()
                    multiLine.numberOfLines = 0
                } else {
                    multiLine.text = "N/A"
                    multiLine.numberOfLines = 1
                }
            default:
                break
            }
            
            return cell
        case .eraseAppSettings:
            let identifier = "sharedUploadEraseAppSettings"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ??
                UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell.selectionStyle = .none
            cell.textLabel?.text = "Erase Application Settings"
            cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
            
            let eraseAppSettingsSwitch = UISwitch()
            eraseAppSettingsSwitch.onTintColor = .nordic
            eraseAppSettingsSwitch.isOn = dfuManagerConfiguration.eraseAppSettings
            eraseAppSettingsSwitch.addTarget(self, action: #selector(updateEraseApplicationSettings), for: .valueChanged)
            cell.accessoryView = eraseAppSettingsSwitch
            uploadEraseAppSettingsSwitch = eraseAppSettingsSwitch
            
            return cell
        case .swapTime:
            let identifier = "sharedUploadSwapTime"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ??
                UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell.selectionStyle = .none
            cell.textLabel?.text = "Swap Time"
            cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
            
            if uploadSwapButton.superview != cell.contentView {
                uploadSwapButton.removeFromSuperview()
                cell.contentView.addSubview(uploadSwapButton)
            }
            if package != nil {
                uploadSwapButton.setTitle("\(dfuManagerConfiguration.estimatedSwapTime)s", for: .normal)
            } else {
                uploadSwapButton.setTitle("N/A", for: .normal)
                uploadSwapButton.isEnabled = false
            }
            
            NSLayoutConstraint.activate([
                uploadSwapButton.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                uploadSwapButton.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                
                cell.contentView.bottomAnchor.constraint(equalTo: uploadSwapButton.bottomAnchor, constant: 8.0)
            ])
            return cell
        case .numberOfBuffers:
            let identifier = "sharedUploadNumberOfBuffers"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ??
                UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell.selectionStyle = .none
            cell.textLabel?.text = "No. of Buffers"
            cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
            
            if uploadBuffersButton.superview != cell.contentView {
                uploadBuffersButton.removeFromSuperview()
                cell.contentView.addSubview(uploadBuffersButton)
            }
            if package != nil {
                uploadBuffersButton.setTitle(dfuManagerConfiguration.pipelineDepth == 1 ? "Disabled" : "\(dfuManagerConfiguration.pipelineDepth + 1)", for: .normal)
            } else {
                uploadBuffersButton.setTitle("N/A", for: .normal)
                uploadBuffersButton.isEnabled = false
            }
            
            NSLayoutConstraint.activate([
                uploadBuffersButton.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                uploadBuffersButton.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                
                cell.contentView.bottomAnchor.constraint(equalTo: uploadBuffersButton.bottomAnchor, constant: 8.0)
            ])
            return cell
        case .byteAlignment:
            let identifier = "sharedUploadByteAlignment"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ??
                UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell.selectionStyle = .none
            
            cell.textLabel?.text = "Byte Alignment"
            cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
            
            if uploadAlignmentButton.superview != cell.contentView {
                uploadAlignmentButton.removeFromSuperview()
                cell.contentView.addSubview(uploadAlignmentButton)
            }
            if package != nil {
                uploadAlignmentButton.setTitle("\(dfuManagerConfiguration.byteAlignment)", for: .normal)
            } else {
                uploadAlignmentButton.setTitle("N/A", for: .normal)
                uploadAlignmentButton.isEnabled = false
            }
            
            NSLayoutConstraint.activate([
                uploadAlignmentButton.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                uploadAlignmentButton.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                
                cell.contentView.bottomAnchor.constraint(equalTo: uploadAlignmentButton.bottomAnchor, constant: 8.0)
            ])
            return cell
        case .fileState:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "sharedFileInfo")
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            
            cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
            cell.textLabel?.text = "State"
            if let dfuError {
                cell.detailTextLabel?.textColor = .systemRed
                cell.detailTextLabel?.text = dfuError.localizedDescription
                cell.detailTextLabel?.numberOfLines = 0
            } else {
                cell.detailTextLabel?.text = dfuState?.description ?? "N/A"
                cell.detailTextLabel?.textColor = dfuState?.associatedColor ?? .secondary
                cell.detailTextLabel?.numberOfLines = 1
            }
            uploadStateLabel = cell.detailTextLabel
            return cell
        case .progressBar:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "progressBar")
            cell.selectionStyle = .none
            
            if uploadSpeedLabel.superview != nil {
                uploadSpeedLabel.removeFromSuperview()
            }
            cell.contentView.addSubview(uploadSpeedLabel)
            
            if uploadProgressView.superview != nil {
                uploadProgressView.removeFromSuperview()
            }
            cell.contentView.addSubview(uploadProgressView)
            NSLayoutConstraint.activate([
                uploadSpeedLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4.0),
                uploadSpeedLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 14.0),
                uploadSpeedLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -8.0),
                
                uploadProgressView.leadingAnchor.constraint(equalTo: cell.contentView.safeLeadingAnchor),
                uploadProgressView.trailingAnchor.constraint(equalTo: cell.contentView.safeTrailingAnchor),
                uploadProgressView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                
                cell.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: uploadSpeedLabel.bottomAnchor, multiplier: 1.0)
            ])
            
            return cell
        case .uploadButtons:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "eraseAppSettings")
            cell.selectionStyle = .none
            
            if uploadCancelButton.superview != nil {
                uploadCancelButton.removeFromSuperview()
            }
            if uploadActionButton.superview != nil {
                uploadActionButton.removeFromSuperview()
            }
            cell.contentView.addSubview(uploadCancelButton)
            cell.contentView.addSubview(uploadActionButton)
            
            uploadActionButton.isEnabled = package != nil && fileError == nil
            
            NSLayoutConstraint.activate([
                uploadActionButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                uploadActionButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -14.0),

                uploadCancelButton.centerYAnchor.constraint(equalTo: uploadActionButton.centerYAnchor),
                uploadCancelButton.trailingAnchor.constraint(equalTo: uploadActionButton.leadingAnchor, constant: -16.0)
            ])
            return cell
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - Selectors

extension ImageController {
    
    // MARK: @objc selectFirmware(_:)
    
    @objc func selectFirmware(_ sender: UIButton) {
        let supportedDocumentTypes = ["com.apple.macbinary-archive", "public.zip-archive", "com.pkware.zip-archive", "com.apple.font-suitcase"]
        let importMenu = UIDocumentPickerViewController(documentTypes: supportedDocumentTypes,
                                                        in: .import)
        importMenu.allowsMultipleSelection = false
        importMenu.delegate = self
        importMenu.popoverPresentationController?.sourceView = sender
        present(importMenu, animated: true, completion: nil)
    }
    
    // MARK: @objc checkForUpdates(_:)
    
    @objc func checkForUpdates(_ sender: UIButton) {
        guard let baseController = parent as? BaseViewController else { return }
        
        otaManager = OTAManager()
        baseController.onDeviceStatusReady { [unowned self] in
            switch otaStatus {
            case .unsupported:
                let alertController = UIAlertController(title: "nRF Cloud Update Unavailable", message: "This device does not support nRF Cloud OTA Updates.", preferredStyle: .alert)
                baseController.present(alertController, addingCancelAction: true, cancelActionTitle: "OK")
            case .missingProjectKey(let deviceInfo, _):
                setProjectKey(for: deviceInfo)
            case .supported(let deviceInfo, let projectKey):
                requestLatestReleaseInfo(for: deviceInfo, using: projectKey)
            case .none:
                break
            }
        }
    }
    
    // MARK: @objc setSwapTime()
    
    @objc func setSwapTime() {
        let alertController = UIAlertController(title: "Swap time (in seconds)", message: nil, preferredStyle: .actionSheet)
        let seconds = [0, 5, 10, 20, 30, 40]
        seconds.forEach { numberOfSeconds in
            alertController.addAction(UIAlertAction(title: "\(numberOfSeconds) seconds", style: .default) { [unowned self] action in
                updateEstimatedSwapTime(to: numberOfSeconds)
                tableView.reloadSections(IndexSet([Section.sharedUpload.rawValue]), with: .none)
            })
        }
        (parent as? BaseViewController)?.present(alertController, addingCancelAction: true)
    }
    
    // MARK: @objc setPipelineDepth()
    
    @objc func setPipelineDepth() {
        let alertController = UIAlertController(title: "Number of buffers", message: nil, preferredStyle: .actionSheet)
        let values = [2, 3, 4, 5, 6, 7, 8]
        values.forEach { value in
            let title = value == values.first ? "Disabled" : "\(value)"
            alertController.addAction(UIAlertAction(title: title, style: .default) { [unowned self]
                action in
                updatePipelineDepth(to: value)
                tableView.reloadSections(IndexSet([Section.sharedUpload.rawValue]), with: .none)
            })
        }
        (parent as? BaseViewController)?.present(alertController, addingCancelAction: true)
    }
    
    // MARK: @objc setByteAlignment()
    
    @objc func setByteAlignment() {
        let alertController = UIAlertController(title: "Byte Alignment", message: nil, preferredStyle: .actionSheet)
        ImageUploadAlignment.allCases.forEach { alignmentValue in
            let text = "\(alignmentValue)"
            alertController.addAction(UIAlertAction(title: text, style: .default) { [unowned self]
                action in
                updateByteAlignment(to: alignmentValue)
                tableView.reloadSections(IndexSet([Section.sharedUpload.rawValue]), with: .none)
            })
        }
        (parent as? BaseViewController)?.present(alertController, addingCancelAction: true)
    }
    
    // MARK: @objc updateEraseApplicationSettings(_:)
    
    @objc func updateEraseApplicationSettings(_ sender: UISwitch) {
        dfuManagerConfiguration.eraseAppSettings = sender.isOn
        updateEraseApplicationSettings(to: sender.isOn)
    }
    
    // MARK: @objc uploadAction(_:)
    
    @objc func uploadAction(_ sender: UIButton) {
        guard let dfuManager, let imageManager else { return }
        if isDFUinProgress() {
            // Pause
            if imageManager.isInProgress() {
                imageManager.pauseUpload()
            } else if dfuManager.isInProgress() {
                dfuManager.pause()
            }
            uploadStateLabel?.text = "Paused"
            uploadStateLabel?.textColor = .secondary
            uploadSpeedLabel.isHidden = true
            
            uploadActionButton.setTitle("Resume", for: .normal)
        } else if dfuManager.isPaused() || imageManager.isPaused() {
            // Resume
            uploadTimestamp = nil
            uploadImageSize = nil
            if imageManager.isPaused() {
                imageManager.continueUpload()
            } else if dfuManager.isPaused() {
                dfuManager.resume()
            }
            uploadStateLabel?.text = "Resuming"
            uploadSpeedLabel.isHidden = false
            
            uploadActionButton.setTitle("Pause", for: .normal)
        } else {
            (parent as? BaseViewController)?.onDeviceStatusReady { [unowned self] in
                if advancedMode {
                    if let envelope = package?.envelope {
                        // SUIT has "no mode" to select
                        // (We use modes in the code only, but SUIT has no concept of upload modes)
                        startFirmwareUpload(envelope: envelope)
                    } else if let package {
                        startFirmwareUpload(package: package)
                    }
                } else {
                    startPackageDFU()
                }
            }
        }
    }
    
    // MARK: @objc uploadCancel(_:)
    
    @objc func uploadCancel(_ sender: UIButton) {
        if dfuManager.isInProgress() {
            dfuManager.cancel()
        } else if imageManager.isInProgress() {
            imageManager.cancelUpload()
        } else {
            uploadSpeedLabel.text = "Cancel requires \(advancedMode ? "Upload" : "Upgrade") in progress"
            uploadSpeedLabel.textColor = .systemYellow
        }
    }
}
 
// MARK: - Internal

internal extension ImageController {
    
    func startPackageDFU() {
        guard let package else { return }
        if package.isForSUIT {
            // SUIT has "no mode" to select
            // (We use modes in the code only, but SUIT has no concept of upload modes)
            startFirmwareUpgrade(package: package)
        } else {
            if package.images.count > 1, package.images.contains(where: { $0.content == .mcuboot }) {
                // Force user to select which 'image' to use for bootloader update.
                selectBootloaderImage(for: package)
            } else {
                selectMode(for: package)
            }
        }
    }
    
    // MARK: selectMode(for:)
    
    func selectMode(for package: McuMgrPackage) {
        let alertController = UIAlertController(title: "Select Mode", message: nil, preferredStyle: .actionSheet)
        FirmwareUpgradeMode.allCases.forEach { upgradeMode in
            let text = "\(upgradeMode)"
            alertController.addAction(UIAlertAction(title: text, style: .default) {
                action in
                self.dfuManagerConfiguration.upgradeMode = upgradeMode
                self.startFirmwareUpgrade(package: package)
            })
        }
        (parent as? BaseViewController)?.present(alertController, addingCancelAction: true)
    }
    
    // MARK: selectBootloaderImage(for:)
    
    func selectBootloaderImage(for package: McuMgrPackage) {
        let alertController = buildSelectImageController()
        for image in package.images {
            alertController.addAction(UIAlertAction(title: image.imageName(), style: .default) { [weak self]
                action in
                self?.dfuManagerConfiguration.eraseAppSettings = false
                self?.dfuManagerConfiguration.upgradeMode = .confirmOnly
                self?.startFirmwareUpgrade(images: [image])
            })
        }
        (parent as? BaseViewController)?.present(alertController, animated: true)
    }
    
    // MARK: startFirmwareUpgrade
    
    func startFirmwareUpgrade(package: McuMgrPackage) {
        dfuManager.start(package: package, using: dfuManagerConfiguration)
    }
    
    func startFirmwareUpgrade(images: [ImageManager.Image]) {
        dfuManager.start(images: images, using: dfuManagerConfiguration)
    }
    
    // MARK: startFirmwareUpload
    
    func startFirmwareUpload(package: McuMgrPackage) {
        uploadImageSize = nil
        
        let configuration = dfuManagerConfiguration
        Task {
            let images: [ImageManager.Image]
            switch await requestBootloaderIfNecessary() {
            case .suit where package.images.count == 1:
                let singleImage: ImageManager.Image! = package.images.first
                let partitions = 0...3
                images = partitions.map {
                    ImageManager.Image(image: $0, hash: singleImage.hash, data: singleImage.data)
                }
            default:
                images = package.images
            }
            
            let alertController = buildSelectImageController()
            for image in images {
                alertController.addAction(UIAlertAction(title: image.imageName(), style: .default) { [weak self]
                    action in
                    self?.uploadWillStart()
                    _ = self?.imageManager.upload(images: [image], using: configuration, delegate: self)
                })
            }
            
            present(alertController, animated: true)
        }
    }
    
    func startFirmwareUpload(envelope: McuMgrSuitEnvelope) {
        // sha256 is the currently only supported mode.
        // The rest are optional to implement in SUIT.
        guard let sha256Hash = envelope.digest.hash(for: .sha256) else {
            uploadDidFail(with: McuMgrSuitParseError.supportedAlgorithmNotFound)
            return
        }
        uploadWillStart()
        let image = ImageManager.Image(image: 0, hash: sha256Hash, data: envelope.data)
        _ = imageManager.upload(images: [image], using: dfuManagerConfiguration, delegate: self)
    }
    
    // MARK: updateEstimatedSwapTime(to:)
    
    func updateEstimatedSwapTime(to numberOfSeconds: Int, updatingUserDefaults: Bool = true) {
        dfuManagerConfiguration.estimatedSwapTime = TimeInterval(numberOfSeconds)
        guard updatingUserDefaults else { return }
        UserDefaults.standard.set(numberOfSeconds, forKey: Key.swapTime.rawValue)
    }
    
    // MARK: updatePipelineDepth(to:)
    
    func updatePipelineDepth(to value: Int, updatingUserDefaults: Bool = true) {
        // Pipeline Depth = Number of Buffers - 1
        dfuManagerConfiguration.pipelineDepth = value - 1
        guard updatingUserDefaults else { return }
        UserDefaults.standard.set(dfuManagerConfiguration.pipelineDepth,
                                  forKey: Key.pipelineDepth.rawValue)
    }
    
    // MARK: updateByteAlignment(to:)
    
    func updateByteAlignment(to byteAlignment: ImageUploadAlignment, updatingUserDefaults: Bool = true) {
        dfuManagerConfiguration.byteAlignment = byteAlignment
        guard updatingUserDefaults else { return }
        UserDefaults.standard.set(byteAlignment.rawValue, forKey: Key.byteAlignment.rawValue)
    }
    
    // MARK: updateBufferSize(to:)
    
    func updateBufferSize(to bufferSize: Int, updatingUserDefaults: Bool = true) {
        dfuManagerConfiguration.reassemblyBufferSize = UInt64(bufferSize)
        guard updatingUserDefaults else { return }
        UserDefaults.standard.set(bufferSize, forKey: Key.chunkSize.rawValue)
    }
    
    // MARK: updateEraseApplicationSettings(to:)
    
    func updateEraseApplicationSettings(to eraseApplicationSettings: Bool, updatingUserDefaults: Bool = true) {
        dfuManagerConfiguration.eraseAppSettings = eraseApplicationSettings
        guard updatingUserDefaults else { return }
        UserDefaults.standard.set(eraseApplicationSettings,
                                  forKey: Key.eraseAppSettings.rawValue)
    }
    
    // MARK: setProjectKey(for:)
    
    private func setProjectKey(for deviceInfo: DeviceInfoToken) {
        let alertController = UIAlertController(title: "Missing Project Key", message: "\nnRF Cloud Project Key is required to continue.", preferredStyle: .alert)
        alertController.addTextField()
        
        // Link rom Memfault documentation: https://docs.memfault.com/docs/mcu/quickstart-nrf5x-ncs
        if let memfaultKeyURL = URL(string: "https://mflt.io/project-key") {
            alertController.addAction(UIAlertAction(title: "Open Project Settings", style: .default, handler: { _ in
                UIApplication.shared.open(memfaultKeyURL, options: [:], completionHandler: nil)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Continue", style: .default) { [unowned self] action in
            guard let textField = alertController.textFields?.first,
                  let keyString = textField.text else { return }
            let key = ProjectKey(keyString)
            requestLatestReleaseInfo(for: deviceInfo, using: key)
        })
        (parent as? BaseViewController)?.present(alertController, addingCancelAction: true)
    }
    
    // MARK: requestLatestReleaseInfo(for:using:)
    
    private func requestLatestReleaseInfo(for deviceInfo: DeviceInfoToken,
                                          using projectKey: ProjectKey) {
        otaManager?.getLatestReleaseInfo(deviceInfo: deviceInfo, projectKey: projectKey) { [unowned self] result in
            switch result {
            case .success(let resultInfo):
                let alertController = UIAlertController(title: "OTA Update Available", message: nil, preferredStyle: .alert)
                let artifact: ReleaseArtifact! = resultInfo.artifacts.first
                let revisionString = resultInfo.revision.isEmpty ? "" : "-\(resultInfo.revision)"
                alertController.message = """
                Firmware version \(resultInfo.version)\(revisionString) (\(artifact.sizeString())) is available with the following release notes:
                
                \(resultInfo.notes)
                """
                alertController.addAction(UIAlertAction(title: "Download", style: .default) { [unowned self] action in
                    download(release: resultInfo)
                })
                (parent as? BaseViewController)?.present(alertController, addingCancelAction: true)
            case .failure(let otaError):
                handleLatestReleaseError(otaError)
            }
        }
    }
    
    private func handleLatestReleaseError(_ otaError: OTAManagerError) {
        switch otaError {
        case .networkError:
            let alertController = UIAlertController(title: "Network Error", message: "Unable to reach the Network.", preferredStyle: .alert)
            (parent as? BaseViewController)?.present(alertController, addingCancelAction: true, cancelActionTitle: "OK")
        case .invalidProjectKey(let deviceInfo):
            setProjectKey(for: deviceInfo)
        case .deviceIsUpToDate:
            let alertController = UIAlertController(title: "Your device is up to date", message: "Your device is already using the latest firmware version available through nRF Cloud OTA.", preferredStyle: .alert)
            (parent as? BaseViewController)?.present(alertController, addingCancelAction: true, cancelActionTitle: "OK")
        default:
            let alertController = UIAlertController(title: "Error Requesting Update", message: otaError.localizedDescription, preferredStyle: .alert)
            (parent as? BaseViewController)?.present(alertController, addingCancelAction: true, cancelActionTitle: "OK")
        }
    }
    
    private func download(release: LatestReleaseInfo) {
        let artifact: ReleaseArtifact! = release.artifacts.first
        otaManager?.download(artifact: artifact) { [unowned self] result in
            switch result {
            case .success(let fileURL):
                select(fileURL)
            case .failure(let error):
                guard let url = artifact.releaseURL() else { return }
                onParseError(error, for: url)
            }
        }
    }
}

// MARK: - FirmwareUpgradeState

extension FirmwareUpgradeState {
    
    var associatedColor: UIColor {
        switch self {
        case .upload, .validate, .test, .confirm:
            return .systemGreen
        case .requestMcuMgrParameters, .bootloaderInfo, .eraseAppSettings, .reset, .resetIntoFirmwareLoader:
            return .systemYellow
        case .success:
            return .nordic
        default:
            return .secondary
        }
    }
}
