/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CoreBluetoothMock

// MARK: - DiscoveredPeripheral

final class DiscoveredPeripheral: NSObject {
    
    // MARK: Properties
    
    public private(set) var basePeripheral: CBMPeripheral
    public private(set) var advertisedName: String
    public private(set) var RSSI: NSNumber = -127
    public private(set) var highestRSSI: NSNumber = -127
    public private(set) var advertisedServices: [CBMUUID]?
    
    // MARK: init
    
    init(_ aPeripheral: CBMPeripheral) {
        basePeripheral = aPeripheral
        advertisedName = ""
        super.init()
    }
    
    func update(withAdvertisementData anAdvertisementDictionary: [String : Any], andRSSI anRSSI: NSNumber) {
        (advertisedName, advertisedServices) = parseAdvertisementData(anAdvertisementDictionary)
        
        if anRSSI.decimalValue != 127 {
            RSSI = anRSSI
        
            if RSSI.decimalValue > highestRSSI.decimalValue {
                highestRSSI = RSSI
            }
        }
    }
    
    private func parseAdvertisementData(_ anAdvertisementDictionary: [String : Any]) -> (String, [CBMUUID]?) {
        var advertisedName: String
        var advertisedServices: [CBMUUID]?
        
        if let name = anAdvertisementDictionary[CBMAdvertisementDataLocalNameKey] as? String {
            advertisedName = name
        } else {
            advertisedName = "N/A"
        }
        if let services = anAdvertisementDictionary[CBMAdvertisementDataServiceUUIDsKey] as? [CBMUUID] {
            advertisedServices = services
        } else {
            advertisedServices = nil
        }
        
        return (advertisedName, advertisedServices)
    }
    
    // MARK: NSObject
    
    override func isEqual(_ object: Any?) -> Bool {
        if object is DiscoveredPeripheral {
            let peripheralObject = object as! DiscoveredPeripheral
            return peripheralObject.basePeripheral.identifier == basePeripheral.identifier
        } else if object is CBMPeripheral {
            let peripheralObject = object as! CBMPeripheral
            return peripheralObject.identifier == basePeripheral.identifier
        } else {
            return false
        }
    }
}
