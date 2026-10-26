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

@MainActor
final class DeviceStatusManager {
    
    // MARK: Private Properties
    
    enum StatusInfoState {
        case ready(Result<DeviceStatusInfo, Error>)
        case inProgress(Task<DeviceStatusInfo, Error>)
        case none
    }
    
    enum OTAState {
        case ready(OTAStatus)
        case inProgress(Task<OTAStatus, Never>)
        case none
    }
    
    private weak var defaultManager: DefaultManager?
    private weak var logDelegate: (any McuMgrLogDelegate)?
    
    private var statusInfoState: StatusInfoState
    private var otaState: OTAState
    
    // MARK: init
    
    init(_ defaultManager: DefaultManager, logDelegate: (any McuMgrLogDelegate)?) {
        self.defaultManager = defaultManager
        self.logDelegate = logDelegate
        self.statusInfoState = .none
        self.otaState = .none
        defaultManager.logDelegate = logDelegate
        logDelegate?.log(#function, ofCategory: .default, atLevel: .debug)
    }
    
    // MARK: deinit
    
    deinit {
        logDelegate?.log(#function, ofCategory: .default, atLevel: .debug)
    }
}

// MARK: API

extension DeviceStatusManager {
    
    // MARK: requestStatusInfo
    
    func requestStatusInfo() async throws -> DeviceStatusInfo {
        switch statusInfoState {
        case .ready(let statusInfo):
            switch statusInfo {
            case .success(let success):
                return success
            case .failure(let failure):
                throw failure
            }
        case .inProgress(let task):
            return try await task.value
        case .none:
            let task = Task {
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
            statusInfoState = .inProgress(task)
            do {
                let result = try await task.value
                statusInfoState = .ready(.success(result))
                return result
            } catch {
                statusInfoState = .ready(.failure(error))
                throw error
            }
        }
    }
    
    // MARK: requestOTAStatus
    
    func requestOTAStatus(for peripheralUUID: UUID) async -> OTAStatus {
        switch otaState {
        case .ready(let status):
            return status
        case .inProgress(let task):
            return await task.value
        case .none:
            let task = Task {
                let deviceInfoManager = DeviceInfoManager(peripheralUUID)
                do {
                    let tokens = try await requestTokensViaMemfaultManager()
                    return OTAStatus.supported(tokens.0, tokens.1)
                } catch {
                    // Disregard error. Try again through Device Information.
                    var deviceInfo: DeviceInfoToken!
                    do {
                        deviceInfo = try await deviceInfoManager.getDeviceInfoToken()
                        let projectKey = try await deviceInfoManager.getProjectKey()
                        return OTAStatus.supported(deviceInfo, projectKey)
                    } catch let managerError as DeviceInfoManagerError {
                        if deviceInfo != nil {
                            return OTAStatus.missingProjectKey(deviceInfo, managerError)
                        } else {
                            return OTAStatus.unsupported(managerError)
                        }
                    } catch let error {
                        return OTAStatus.unsupported(error)
                    }
                }
            }
            
            otaState = .inProgress(task)
            let result = await task.value
            otaState = .ready(result)
            return result
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
