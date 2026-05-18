/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import CoreBluetooth
import iOS_Common_Libraries

// MARK: - ScannerTableViewCell

final class ScannerTableViewCell: UITableViewCell {
    
    // MARK: reuseIdentifier
    
    static let reuseIdentifier = "deviceItem"
    
    // MARK: Private Properties
    
    private var lastUpdateTimestamp = Date()
    private var peripheral: DiscoveredPeripheral!

    // MARK: setupViewWithPeripheral(:_)
    
    public func setupViewWithPeripheral(_ peripheral: DiscoveredPeripheral) {
        textLabel?.text = peripheral.advertisedName
        
        if accessoryView == nil {
            accessoryView = UIImageView()
            (accessoryView as? UIImageView)?.frame = CGRect(origin: .zero, size: .init(asSquare: 28.0))
            (accessoryView as? UIImageView?)??.tintColor = .nordic
        }
        let rssi = peripheral.RSSI.decimalValue
        if rssi < -60 {
            (accessoryView as? UIImageView)?.image = #imageLiteral(resourceName: "rssi_2")
        } else if rssi < -50 {
            (accessoryView as? UIImageView)?.image = #imageLiteral(resourceName: "rssi_3")
        } else if rssi < -30 {
            (accessoryView as? UIImageView)?.image = #imageLiteral(resourceName: "rssi_2")
        } else {
            (accessoryView as? UIImageView)?.image = #imageLiteral(resourceName: "rssi_1")
        }
    }
    
    // MARK: peripheralUpdatedAdvertisementData(_:)
    
    public func peripheralUpdatedAdvertisementData(_ peripheral: DiscoveredPeripheral) {
        if Date().timeIntervalSince(lastUpdateTimestamp) > 1.0 {
            lastUpdateTimestamp = Date()
            setupViewWithPeripheral(peripheral)
        }
    }
}
