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
            uploadCancelButton.isEnabled = true
            
            uploadSelectFile?.isEnabled = false
            uploadCheckForUpdates?.isEnabled = false
            uploadEraseAppSettingsSwitch?.isEnabled = false
            
            resetButton?.isEnabled = false
            
            imagesTestButton?.isEnabled = false
            imagesConfirmButton?.isEnabled = false
            imagesEraseButton?.isEnabled = false
            return
        default:
            break
        }
        
        uploadCancelButton.isEnabled = false
        
        uploadSelectFile?.isEnabled = true
        uploadCheckForUpdates?.isEnabled = true
        uploadEraseAppSettingsSwitch?.isEnabled = true
        
        imagesReadButton?.isEnabled = true
        settingsEraseButton?.isEnabled = true
        resetButton?.isEnabled = true
        
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
        
        imagesReadButton?.isEnabled = false
        imagesTestButton?.isEnabled = false
        imagesConfirmButton?.isEnabled = false
        imagesEraseButton?.isEnabled = false
        
        settingsEraseButton?.isEnabled = false
        
        resetButton?.isEnabled = false
    }
}
