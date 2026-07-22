//
//  ImageController+UpgradeDelegate.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 08/07/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation
import iOSMcuManagerLibrary

// MARK: - FirmwareUpgradeDelegate

extension ImageController: FirmwareUpgradeDelegate {
    
    func upgradeDidStart(controller: FirmwareUpgradeController) {
        uploadSwapButton.isHidden = true
        uploadBuffersButton.isHidden = true
        uploadAlignmentButton.isHidden = true
        uploadActionButton.setTitle("Pause", for: .normal)

        uploadCancelButton.isHidden = false
        uploadCancelButton.isEnabled = true

        initialBytes = 0
        uploadImageSize = nil
        disableActionableButtons()
        
        guard let baseController = parent as? BaseViewController else { return }
        baseController.stopObservability()
    }
    
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        dfuState = newState
        uploadCancelButton.isEnabled = dfuManager.isInProgress() || imageManager.isInProgress()
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
        tableView.reloadSections(IndexSet([Section.sharedUpload.rawValue]), with: .none)
    }
    
    func upgradeDidComplete() {
        uploadProgressView.setProgress(0, animated: false)
        uploadCancelButton.isHidden = true
        uploadSwapButton.isHidden = false
        uploadBuffersButton.isHidden = false
        uploadAlignmentButton.isHidden = false
        uploadActionButton.setTitle("Start", for: .normal)

        uploadSelectFile?.isEnabled = true
        uploadCheckForUpdates?.isEnabled = true
        uploadEraseAppSettingsSwitch?.isEnabled = true
        updateActionableButtonsState()
    }
    
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        uploadProgressView.setProgress(0, animated: true)
        uploadCancelButton.isHidden = true
        uploadSwapButton.isHidden = false
        uploadBuffersButton.isHidden = false
        uploadAlignmentButton.isHidden = false
        uploadActionButton.setTitle("Start", for: .normal)

        uploadSelectFile?.isEnabled = true
        uploadCheckForUpdates?.isEnabled = true
        uploadEraseAppSettingsSwitch?.isEnabled = true
        uploadStateLabel?.textColor = .systemRed
        uploadStateLabel?.text = error.localizedDescription
        uploadStateLabel?.numberOfLines = 0
        uploadSpeedLabel.isHidden = true
        updateActionableButtonsState()
    }
    
    func upgradeDidCancel(state: FirmwareUpgradeState) {
        uploadProgressView.setProgress(0, animated: true)
        uploadCancelButton.isHidden = true
        uploadSwapButton.isHidden = false
        uploadBuffersButton.isHidden = false
        uploadAlignmentButton.isHidden = false
        uploadSelectFile?.isEnabled = true
        uploadCheckForUpdates?.isEnabled = true
        uploadEraseAppSettingsSwitch?.isEnabled = true
        uploadStateLabel?.textColor = .secondary
        uploadStateLabel?.text = "CANCELLED"
        uploadStateLabel?.numberOfLines = 1
        uploadSpeedLabel.isHidden = true
        
        uploadActionButton.setTitle("Start", for: .normal)
    }
    
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        uploadSpeedLabel.isHidden = false

        let percentage = Float(bytesSent) / Float(imageSize)
        if uploadImageSize == nil || uploadImageSize != imageSize {
            uploadTimestamp = timestamp
            uploadImageSize = imageSize
            initialBytes = bytesSent
            uploadProgressView.setProgress(percentage, animated: false)
        } else {
            uploadProgressView.setProgress(percentage, animated: true)
        }
        
        if dfuManager.isInProgress() || imageManager.isInProgress() {
            uploadStateLabel?.text = "\(FirmwareUpgradeState.upload.description) (\(String(format: "%.0f%", percentage * 100.0))%)"
            uploadStateLabel?.textColor = FirmwareUpgradeState.upload.associatedColor
        }
        
        // Date.timeIntervalSince1970 returns seconds
        let msSinceUploadBegan = max((timestamp.timeIntervalSince1970 - uploadTimestamp.timeIntervalSince1970) * 1000, 1)
        
        guard bytesSent < imageSize else {
            let averageSpeedInKiloBytesPerSecond = Double(imageSize - initialBytes) / msSinceUploadBegan
            uploadSpeedLabel.text = "\(imageSize) bytes sent (avg \(String(format: "%.2f kB/s", averageSpeedInKiloBytesPerSecond)))"
            return
        }
        
        let bytesSentSinceUploadBegan = bytesSent - initialBytes
        // bytes / ms = kB/s
        let speedInKiloBytesPerSecond = Double(bytesSentSinceUploadBegan) / msSinceUploadBegan
        uploadSpeedLabel.text = String(format: "%.2f kB/s", speedInKiloBytesPerSecond)
        uploadSpeedLabel.textColor = .secondary
    }
}

// MARK: - Suit Upgrade Delegate

extension ImageController: SuitFirmwareUpgradeDelegate {
    
    func uploadRequestsResource(_ resource: FirmwareUpgradeResource) {
        guard let package else { return }
        guard let resourceImage = package.image(forResource: resource) else {
            upgradeDidFail(inState: .upload, with: McuMgrPackage.Error.resourceNotFound(resource))
            return
        }
        dfuManager.uploadResource(resource, data: resourceImage.data)
    }
}

// MARK: - ImageUploadDelegate

extension ImageController: ImageUploadDelegate {
    
    func uploadWillStart() {
        uploadSwapButton.isHidden = true
        uploadBuffersButton.isHidden = true
        uploadAlignmentButton.isHidden = true
        uploadActionButton.setTitle("Pause", for: .normal)

        uploadCancelButton.isHidden = false
        initialBytes = 0
        uploadImageSize = nil
        
        uploadStateLabel?.text = "Starting"
        disableActionableButtons()
        
        guard let baseController = parent as? BaseViewController else { return }
        baseController.stopObservability()
    }
    
    func uploadDidFail(with error: Error) {
        upgradeStateDidChange(from: .upload, to: .none)
        upgradeDidFail(inState: .upload, with: error)
    }
    
    func uploadDidCancel() {
        upgradeStateDidChange(from: .upload, to: .none)
        upgradeDidCancel(state: .upload)
    }
    
    func uploadDidFinish() {
        upgradeStateDidChange(from: .upload, to: .success)
        upgradeDidComplete()
    }
}
