//
//  BasicManager+Async.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 21/07/2026.
//

import Foundation
import iOSMcuManagerLibrary

// MARK: - DefaultManager+Async

@available(iOS 13.0, macCatalyst 13.0, macOS 10.15, *)
public extension BasicManager {
    
    // MARK: async eraseAppSettings()
    
    /// Async variant of ``eraseAppSettings()``
    public func eraseAppSettings() async throws -> McuMgrResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrResponse, Error>) in
            eraseAppSettings() { response, error in
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
}
