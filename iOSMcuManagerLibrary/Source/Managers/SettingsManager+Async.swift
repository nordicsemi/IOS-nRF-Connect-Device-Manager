//
//  SettingsManager+Async.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 16/06/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation

// MARK: - SettingsManager+Async

@available(iOS 13.0, macCatalyst 13.0, macOS 10.15, *)
public extension SettingsManager {
    
    // MARK: async write()
    
    public func write(name: String, value: [UInt8]) async throws -> McuMgrResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrResponse, Error>) in
            write(name: name, value: value) { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let response {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: McuMgrResponseParseError.invalidPayload)
                }
            }
        }
    }
    
    // MARK: async save()
    
    public func save() async throws -> McuMgrResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrResponse, Error>) in
            send(op: .write, commandId: ConfigID.three, payload: nil) { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let response {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: McuMgrResponseParseError.invalidPayload)
                }
            }
        }
    }
    
    // MARK: async setFirmwareLoaderAdvertisingName(_:)
    
    public func setFirmwareLoaderAdvertisingName(_ name: String) async throws -> McuMgrResponse {
        do {
            let nameBlob: [UInt8] = Array(name.utf8)
            try await write(name: "fw_loader/adv_name", value: nameBlob)
            return try await save()
        } catch {
            throw error
        }
    }
}
