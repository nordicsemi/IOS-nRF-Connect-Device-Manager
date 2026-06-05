//
//  FileSystemManager+Async.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 05/06/2026.
//

import Foundation

// MARK: - FileSystemManager

public extension FileSystemManager {
    
    // MARK: upload
    
    @MainActor
    public func upload(_ name: String, data: Data, using configuration: FirmwareUpgradeConfiguration = FirmwareUpgradeConfiguration()) -> AsyncStream<AsyncFileSystemEvent> {
        let asyncDelegate = AsyncFileSystemDelegate(name: name, data: data)
        self.asyncDelegate = asyncDelegate
        
        let result = upload(name: name, data: data, using: configuration, delegate: asyncDelegate)
        if !result {
            defer {
                // deferred so stream listener can get it.
                asyncDelegate.send(.operationDidFail(FileSystemManagerError.operationAlreadyInProgress))
            }
        }
        return asyncDelegate.stream
    }
    
    // MARK: download
    
    @MainActor
    public func download(_ path: String) -> AsyncStream<AsyncFileSystemEvent> {
        let asyncDelegate = AsyncFileSystemDelegate(name: path)
        self.asyncDelegate = asyncDelegate
        let result = download(name: path, delegate: asyncDelegate)
        if !result {
            defer {
                // deferred so stream listener can get it.
                asyncDelegate.send(.operationDidFail(FileSystemManagerError.operationAlreadyInProgress))
            }
        }
        return asyncDelegate.stream
    }
}

// MARK: - AsyncFileSystemEvent

public enum AsyncFileSystemEvent {
    
    case progressDidChange(progressSize: Int, fileSize: Int, timestamp: Date)
    case operationDidFail(_ error: Error)
    case operationCancelled
    case operationFinished(filename: String, data: Data)
}

// MARK: - AsyncFileSystemDelegate

/**
 - Warning: Marked for `internal` use for now. We need to figure out if
 this is how we want to handle bridging the current API into the
 [Structured Concurrency](https://developer.apple.com/documentation/swift/concurrency) paradigm.
 */
final internal class AsyncFileSystemDelegate {
    
    public typealias Stream = AsyncStream<AsyncFileSystemEvent>
    
    private let name: String
    private let data: Data!
    
    private(set) var stream: Stream!
    private var continuation: Stream.Continuation!
    
    init(name: String, data: Data? = nil) {
        self.name = name
        self.data = data
        self.stream = Stream() { [unowned self] continuation in
            self.continuation = continuation
        }
    }
    
    func send(_ event: AsyncFileSystemEvent) {
        continuation.yield(event)
    }
}

// MARK: - FileUploadDelegate

extension AsyncFileSystemDelegate: FileUploadDelegate {
    
    func uploadProgressDidChange(bytesSent: Int, fileSize: Int, timestamp: Date) {
        continuation?.yield(.progressDidChange(progressSize: bytesSent, fileSize: fileSize, timestamp: timestamp))
    }
    
    func uploadDidFail(with error: any Error) {
        continuation?.yield(.operationDidFail(error))
        continuation?.finish()
    }
    
    func uploadDidCancel() {
        continuation?.yield(.operationCancelled)
        continuation?.finish()
    }
    
    func uploadDidFinish() {
        continuation.yield(.operationFinished(filename: name, data: data))
        continuation?.finish()
    }
}

// MARK: - FileDownloadDelegate

extension AsyncFileSystemDelegate: FileDownloadDelegate {
    
    func downloadProgressDidChange(bytesDownloaded: Int, fileSize: Int, timestamp: Date) {
        continuation?.yield(.progressDidChange(progressSize: bytesDownloaded, fileSize: fileSize, timestamp: timestamp))
    }
    
    func downloadDidFail(with error: any Error) {
        continuation?.yield(.operationDidFail(error))
        continuation?.finish()
    }
    
    func downloadDidCancel() {
        continuation?.yield(.operationCancelled)
        continuation?.finish()
    }
    
    func download(of name: String, didFinish data: Data) {
        continuation?.yield(.operationFinished(filename: self.name, data: data))
        continuation?.finish()
    }
}
