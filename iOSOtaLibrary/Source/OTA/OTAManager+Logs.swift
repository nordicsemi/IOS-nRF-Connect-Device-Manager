//
//  OTAManager+Logs.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 30/07/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - Logs

extension OTAManager {
    
    func log(_ string: String) {
        guard #available(iOS 14.0, macCatalyst 14.0, macOS 11.0, *) else {
            print(string)
            return
        }
        let log = NordicLog(Self.self, subsystem: "com.nordicsemi.ios_ota_library")
        log.debug(string)
    }
    
    func logError(_ string: String) {
        guard #available(iOS 14.0, macCatalyst 14.0, macOS 11.0, *) else {
            print("Error: \(string)")
            return
        }
        let log = NordicLog(Self.self, subsystem: "com.nordicsemi.ios_ota_library")
        log.error(string)
    }
}
