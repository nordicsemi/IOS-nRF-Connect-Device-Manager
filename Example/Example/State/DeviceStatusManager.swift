//
//  DeviceStatusState.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 26/3/26.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation
import SwiftUI
import iOSMcuManagerLibrary
import iOSOtaLibrary

// MARK: - DeviceStatusManager

final class DeviceStatusManager {
    
    // MARK: Private Properties
    
    private weak var defaultManager: DefaultManager?
    private weak var logDelegate: (any McuMgrLogDelegate)?
    
    // MARK: init
    
    init(_ defaultManager: DefaultManager, logDelegate: (any McuMgrLogDelegate)?) {
        self.defaultManager = defaultManager
        self.logDelegate = logDelegate
        defaultManager.logDelegate = logDelegate
    }
}

// MARK: API

extension DeviceStatusManager {
    
    // MARK: requestStatusInfo
    
    func requestStatusInfo() async throws -> DeviceStatusInfo {
        // We bail out if one of them fails because they might fail due to
        // disconnection. If we follow-up with the next, it might spurn the
        // transport into reconnecting without this being the user's intention.
        let mcuMgrParametersResponse = try await defaultManager?.params()
        let appInfoResponse = try await defaultManager?.applicationInfo(format: [.kernelName, .kernelVersion])
        let bootloaderInfo = try await defaultManager?.bootloaderInfo()
        
        var info = DeviceStatusInfo()
        if let mcuMgrParametersResponse {
            info.bufferSize = mcuMgrParametersResponse.bufferSize
            info.bufferCount = mcuMgrParametersResponse.bufferCount
        }
        info.appInfoOutput = appInfoResponse?.response
        info.bootloader = bootloaderInfo?.bootloader
        info.bootloaderMode = bootloaderInfo?.mode
        info.bootloaderSlot = bootloaderInfo?.slot
        return info
    }
    
    // MARK: requestOTAStatus
    
    func requestOTAStatus(for peripheralUUID: UUID) async -> OTAStatus {
        let deviceInfoManager = DeviceInfoManager(peripheralUUID)
        do {
            let tokens = try await requestTokensViaMemfaultManager()
            return .supported(tokens.0, tokens.1)
        } catch {
            // Disregard error. Try again through Device Information.
            var deviceInfo: DeviceInfoToken!
            do {
                deviceInfo = try await deviceInfoManager.getDeviceInfoToken()
                let projectKey = try await deviceInfoManager.getProjectKey()
                return .supported(deviceInfo, projectKey)
            } catch let managerError as DeviceInfoManagerError {
                if deviceInfo != nil {
                    return .missingProjectKey(deviceInfo, managerError)
                } else {
                    return .unsupported(managerError)
                }
            } catch let error {
                return .unsupported(error)
            }
        }
    }
}

// MARK: - Private

fileprivate extension DeviceStatusManager {
    
    // MARK: requestTokensViaMemfaultManager
    
    func requestTokensViaMemfaultManager() async throws -> (DeviceInfoToken, ProjectKey) {
        guard let transport = defaultManager?.transport else {
            throw ObservabilityError.mdsServiceNotFound
        }
        let otaManager = OTAManager()
        otaManager.logDelegate = logDelegate
        let deviceInfo = try await otaManager.getDeviceInfoToken(via: transport)
        let projectKey = try await otaManager.getProjectKey(via: transport)
        return (deviceInfo, projectKey)
    }
}

// MARK: - DeviceStatusInfo

struct DeviceStatusInfo {
    
    var bufferCount: UInt64?
    var bufferSize: UInt64?
    var appInfoOutput: String?
    var bootloader: BootloaderInfoResponse.Bootloader?
    var bootloaderMode: BootloaderInfoResponse.Mode?
    var bootloaderSlot: UInt64?
}

// MARK: - Delegate

extension DeviceStatusManager {
    
    protocol Delegate: AnyObject {
        
        func statusInfoDidChange(_ info: DeviceStatusInfo)
        func transportStateDidChange(_ state: PeripheralState)
        func otaStatusChanged(_ status: OTAStatus)
        func observabilityStatusChanged(_ statusInfo: ObservabilityStatusInfo)
    }
}
