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
        disableActionableButtons()
        uploadCancelButton.isHidden = false
        uploadActionButton.setTitle("Pause", for: .normal)

        dfuError = nil
        lastBytesSent = 0
        lastBytesSentTimestamp = nil
        uploadStartTimestamp = nil
        uploadStartBytesSent = 0
        uploadImageSize = nil
        
        baseController?.stopObservability()
    }
    
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        dfuState = newState
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
        tableView.reloadSections(IndexSet([Section.sharedUpload.rawValue]), with: .none)
        
        updateActionableButtonsState(for: newState)
    }
    
    func upgradeDidComplete() {
        uploadProgressView.setProgress(0, animated: false)
        uploadCancelButton.isHidden = true
        uploadActionButton.setTitle("Start", for: .normal)

        updateActionableButtonsState(for: .success)
    }
    
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        dfuError = error
        tableView.reloadSections(IndexSet([Section.sharedUpload.rawValue]), with: .none)
        
        uploadProgressView.setProgress(0, animated: true)
        uploadCancelButton.isHidden = true
        uploadActionButton.setTitle("Start", for: .normal)

        updateActionableButtonsState(for: .none)
    }
    
    func upgradeDidCancel(state: FirmwareUpgradeState) {
        dfuState = nil
        dfuError = nil
        
        uploadProgressView.setProgress(0, animated: true)
        uploadCancelButton.isHidden = true
        
        uploadStateLabel?.textColor = .secondary
        uploadStateLabel?.text = "CANCELLED"
        uploadStateLabel?.numberOfLines = 1
        uploadSpeedLabel.isHidden = true
        
        uploadActionButton.setTitle("Start", for: .normal)
        updateActionableButtonsState(for: .none)
    }
    
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        uploadSpeedLabel.isHidden = false

        let percentage = Float(bytesSent) / Float(imageSize)
        let bytesSentSinceLastCallback: Int
        if uploadImageSize == nil || uploadImageSize != imageSize {
            uploadImageSize = imageSize
            uploadStartTimestamp = timestamp
            uploadStartBytesSent = bytesSent
            
            lastBytesSent = bytesSent
            lastBytesSentTimestamp = timestamp
            bytesSentSinceLastCallback = bytesSent
            uploadProgressView.setProgress(percentage, animated: false)
        } else {
            bytesSentSinceLastCallback = bytesSent - lastBytesSent
            uploadProgressView.setProgress(percentage, animated: true)
        }
        
        if isDFUinProgress() {
            uploadStateLabel?.textColor = FirmwareUpgradeState.upload.associatedColor
        }
        
        guard bytesSent < imageSize else {
            // Date.timeIntervalSince1970 returns (fractional) seconds as Double
            let msSinceUploadBegan = max((timestamp.timeIntervalSince1970 - uploadStartTimestamp.timeIntervalSince1970) * 1000.0, 1.0)
            let averageSpeedInKiloBytesPerSecond = Double(imageSize - uploadStartBytesSent) / msSinceUploadBegan
            
            if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *) {
                let fileSizeMeasurement = Measurement<UnitInformationStorage>(value: Double(imageSize), unit: .bytes)
                uploadSpeedLabel.text = "\(fileSizeMeasurement.formatted(.byteCount(style: .file))) sent (avg \(String(format: "%.2f kB/s", averageSpeedInKiloBytesPerSecond)))"
            } else {
                uploadSpeedLabel.text = "\(imageSize) bytes sent (avg \(String(format: "%.2f kB/s", averageSpeedInKiloBytesPerSecond)))"
            }
            return
        }
        
        // Date.timeIntervalSince1970 returns (fractional) seconds as Double
        let msSinceLastCallback = max(
            (timestamp.timeIntervalSince1970 - lastBytesSentTimestamp.timeIntervalSince1970) * 1000.0, 1.0
        )
        
        // Don't update UI too quickly. Also resolves first callback (msSinceLastCallback == 1)
        // (Alternative: Timer that averages speed within the firing window, like green robot does.)
        guard msSinceLastCallback > 125.0 else { return }
        lastBytesSentTimestamp = timestamp
        lastBytesSent = bytesSent
        
        // bytes / ms = kB/s
        let speedInKiloBytesPerSecond = Double(bytesSentSinceLastCallback) / msSinceLastCallback
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
        uploadActionButton.setTitle("Pause", for: .normal)

        uploadCancelButton.isHidden = false
        dfuError = nil
        
        lastBytesSent = 0
        lastBytesSentTimestamp = nil
        uploadStartTimestamp = nil
        uploadStartBytesSent = 0
        
        uploadImageSize = nil
        
        uploadStateLabel?.text = "Starting"
        disableActionableButtons()
        
        baseController?.stopObservability()
    }
    
    func uploadDidFail(with error: Error) {
        upgradeStateDidChange(from: .upload, to: .none)
        upgradeDidFail(inState: .upload, with: error)
    }
    
    func uploadDidCancel() {
        upgradeStateDidChange(from: .upload, to: .cancelled)
        upgradeDidCancel(state: .upload)
    }
    
    func uploadDidFinish() {
        upgradeStateDidChange(from: .upload, to: .success)
        upgradeDidComplete()
    }
}
