//
//  StatsManager+Async.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 02/06/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation

// MARK: - StatsManager+Async

@available(iOS 13.0, macCatalyst 13.0, macOS 10.15, *)
public extension StatsManager {
    
    // MARK: async list()
    
    /// Async variant of ``list(callback:)``
    public func list() async throws -> McuMgrStatsListResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrStatsListResponse, Error>) in
            list { response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let response {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: McuMgrResponseParseError.invalidPayload)
                }
            }
        }
    }
    
    // MARK: async read(module:)
    
    /// Async variant of ``read(module:callback:)``
    public func read(module: String) async throws -> McuMgrStatsResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrStatsResponse, Error>) in
            read(module: module) { response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let response {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: McuMgrResponseParseError.invalidPayload)
                }
            }
        }
    }
}
