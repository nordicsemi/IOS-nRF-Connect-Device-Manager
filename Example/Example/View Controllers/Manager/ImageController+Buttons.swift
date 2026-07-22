//
//  ImageController+Buttons.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 22/07/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation

extension ImageController {
    
    // MARK: updateActionableButtonsState()
    
    internal func updateActionableButtonsState() {
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
