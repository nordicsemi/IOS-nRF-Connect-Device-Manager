//
//  ImageController+Buttons.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 22/07/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import iOSMcuManagerLibrary

extension ImageController {
    
    // MARK: updateActionableButtonsState()
    
    internal func updateActionableButtonsState(for state: FirmwareUpgradeState) {
        switch state {
        case .reset, .upload:
            disableActionableButtons()
            return
        default:
            break
        }
        
        uploadSelectFile?.isEnabled = !isDFUinProgress()
        uploadCheckForUpdates?.isEnabled = !isDFUinProgress()
        uploadEraseAppSettingsSwitch?.isEnabled = !isDFUinProgress()
        
        uploadSwapButton.isEnabled = !isDFUinProgress()
        uploadBuffersButton.isEnabled = !isDFUinProgress()
        uploadAlignmentButton.isEnabled = !isDFUinProgress()
        
        imagesReadButton?.isEnabled = !isDFUinProgress()
        settingsEraseButton?.isEnabled = !isDFUinProgress()
        resetButton?.isEnabled = !isDFUinProgress()
        
        guard let images = readImagesResponse?.images else {
            imagesTestButton?.isEnabled = false
            imagesConfirmButton?.isEnabled = false
            imagesEraseButton?.isEnabled = false
            return
        }
        imagesTestButton?.isEnabled = images.first(where: { !$0.active && !$0.pending }) != nil
        imagesConfirmButton?.isEnabled = images.first(where: { !$0.active && !$0.permanent }) != nil
        imagesEraseButton?.isEnabled = images.first(where: { !$0.active && !$0.confirmed }) != nil
    }
    
    // MARK: disableActionableButtons()
    
    internal func disableActionableButtons() {
        uploadSelectFile?.isEnabled = false
        uploadCheckForUpdates?.isEnabled = false
        uploadEraseAppSettingsSwitch?.isEnabled = false
        
        uploadSwapButton.isEnabled = false
        uploadBuffersButton.isEnabled = false
        uploadAlignmentButton.isEnabled = false
        
        imagesReadButton?.isEnabled = false
        imagesTestButton?.isEnabled = false
        imagesConfirmButton?.isEnabled = false
        imagesEraseButton?.isEnabled = false
        
        settingsEraseButton?.isEnabled = false
        
        resetButton?.isEnabled = false
    }
}
