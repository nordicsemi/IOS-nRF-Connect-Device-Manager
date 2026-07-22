/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import iOSMcuManagerLibrary

// MARK: - McuMgrViewController

protocol McuMgrViewController {

    var transport: McuMgrTransport! { get set }
    
    func buildSelectImageController(onCancel onCancelCallback: (() -> Void)?) -> UIAlertController
}

// MARK: buildSelectImageController()

extension McuMgrViewController where Self: UIViewController {
    
    func buildSelectImageController(onCancel onCancelCallback: (() -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: "Select", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
            guard let onCancelCallback else { return }
            onCancelCallback()
        })
    
        // If the device is an iPad set the popover presentation controller
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = self.view
            presenter.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            presenter.permittedArrowDirections = []
        }
        
        return alertController
    }
}

protocol ExtendedMcuMgrViewController: McuMgrViewController, UIViewController {
    
    var bootloader: BootloaderInfoResponse.Bootloader? { get set }
    var defaultManager: DefaultManager! { get }
    
    func requestBootloaderIfNecessary() async -> BootloaderInfoResponse.Bootloader
}

// MARK: requestBootloaderIfNecessary(sender:callback:)

extension ExtendedMcuMgrViewController where Self: UIViewController {
    
    func requestBootloaderIfNecessary() async -> BootloaderInfoResponse.Bootloader {
        guard let bootloader else {
            self.bootloader = (try? await defaultManager.bootloaderInfo().bootloader) ?? .mcuboot
            return self.bootloader ?? .mcuboot
        }
        return bootloader
    }
}
