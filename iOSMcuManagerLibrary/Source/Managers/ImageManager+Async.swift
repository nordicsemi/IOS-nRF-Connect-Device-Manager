//
//  ImageManager+Async.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 09/07/2026.
//

import Foundation

// MARK: - ImageManager+Async

@available(iOS 13.0, macCatalyst 13.0, macOS 10.15, *)
public extension ImageManager {
    
    // MARK: list() async
    
    public func list() async throws -> McuMgrImageStateResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrImageStateResponse, Error>) in
            var alreadyResumed: Bool = false
            list() { response, error in
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
    
    // MARK: test() async
    
    public func test(hash: [UInt8]) async throws -> McuMgrImageStateResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrImageStateResponse, Error>) in
            var alreadyResumed: Bool = false
            test(hash: hash) { response, error in
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
    
    // MARK: confirm() async
    
    public func confirm(hash: [UInt8]) async throws -> McuMgrImageStateResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrImageStateResponse, Error>) in
            var alreadyResumed: Bool = false
            confirm(hash: hash) { response, error in
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
    
    // MARK: erase() async throws
    
    public func erase(image: Int? = nil, slot: Int? = nil) async throws -> McuMgrResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrResponse, Error>) in
            var alreadyResumed: Bool = false
            erase(image: image, slot: slot) { response, error in
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
