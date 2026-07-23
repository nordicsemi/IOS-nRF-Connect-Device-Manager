//
//  SuitManager+Async.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 09/07/2026.
//

import Foundation

// MARK: - SuitManager+Async

@available(iOS 13.0, macCatalyst 13.0, macOS 10.15, *)
public extension SuitManager {
    
    // MARK: listManifest()
    
    public func listManifest() async throws -> SuitListResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SuitListResponse, Error>) in
            var alreadyResumed: Bool = false
            listManifest { response, error in
                guard !alreadyResumed else { return }
                defer {
                    alreadyResumed = true
                }
                
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
    
    // MARK: processRecentlyUploadedEnvelope()
    
    public func processRecentlyUploadedEnvelope() async throws -> McuMgrResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrResponse, Error>) in
            var alreadyResumed: Bool = false
            processRecentlyUploadedEnvelope() { response, error in
                guard !alreadyResumed else { return }
                defer {
                    alreadyResumed = true
                }
                
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
    
    // MARK: cleanup()
    
    public func cleanup() async throws -> McuMgrResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrResponse, Error>) in
            var alreadyResumed: Bool = false
            cleanup { response, error in
                guard !alreadyResumed else { return }
                defer {
                    alreadyResumed = true
                }
                
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
