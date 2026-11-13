//
//  McuMgrUploadPipeline.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 29/10/24.
//

import Foundation

// MARK: - McuMgrUploadPipeline

public struct McuMgrUploadPipeline {
    
    // MARK: Private Properties
    
    private var phase: Phase
    private let bufferSize: UInt64
    private var lastReceivedOffset: UInt64
    private var expectedReturnOffsets: [UInt64] = []
    private var pendingUnflushedCallbacks: Int
    
    private weak var transport: McuMgrTransport?
    private weak var logDelegate: McuMgrLogDelegate?
    
    // MARK: Internal Properties
    
    enum Phase {
        case start
        case rampUp(_ depth: Int)
        case stable(_ depth: Int)
        case throttled(_ depth: Int)
        
        var depth: Int {
            switch self {
            case .start:
                return 1
            case .rampUp(let depth):
                return depth
            case .stable(let depth):
                return depth
            case .throttled(let depth):
                return depth
            }
        }
        
        func throttledDown() -> Phase? {
            switch self {
            case .start:
                return nil
            case .rampUp(let depth), .stable(let depth), .throttled(let depth):
                guard depth - 1 >= 1 else { return nil }
                return .throttled(depth - 1)
            }
        }
    }
    
    let maxDepth: Int
    
    var inFlight: Int { expectedReturnOffsets.count }
    var availablePipelineSlots: Int { phase.depth - inFlight }
    
    // MARK: init
    
    public init(adopting configuration: FirmwareUpgradeConfiguration, over transport: McuMgrTransport,
                logDelegate: McuMgrLogDelegate?) {
        self.maxDepth = max(1, configuration.pipelineDepth)
        self.bufferSize = configuration.reassemblyBufferSize
        self.lastReceivedOffset = 0
        self.pendingUnflushedCallbacks = 0
        self.transport = transport
        self.logDelegate = logDelegate
        self.phase = .start
        phaseChangeTo(.start)
        
        if let bleTransport = transport as? McuMgrBleTransport {
            bleTransport.numberOfParallelWrites = phase.depth
            bleTransport.chunkSendDataToMtuSize = bufferSize != 0 // && bufferSize > mtu ?
//            bleTransport.chunkSendDataToMtuSize = bufferSize != 0 && bufferSize > transport.mtu
        }
    }
    
    // MARK: pipelinedSend(ofSize:using:)
    
    mutating public func pipelinedSend(ofSize imageSize: Int, using sendFrom: @escaping (_ offset: UInt64) -> UInt64) {
        for i in 0..<availablePipelineSlots {
            let maxUnflushedCallbacks = 0 // constant
            guard pendingUnflushedCallbacks <= maxUnflushedCallbacks else {
                // Throttling down.
                // Don't call sendFrom() or we will be sending offsets out of sync with target device.
                return
            }
            
            let offset = expectedReturnOffsets.last ?? lastReceivedOffset
            guard offset < imageSize else {
                return
            }
            let returnOffset = sendFrom(offset)
            expectedReturnOffsets.append(returnOffset)
        }
    }
    
    // MARK: receivedData(with:)
    
    mutating public func receivedData(with offset: UInt64) {
        if expectedReturnOffsets.contains(offset) {
            switch phase {
            case .start, .rampUp:
                // We expect In-Order Responses during good ramp-up.
                if let firstExpectedOffset = expectedReturnOffsets.first, firstExpectedOffset == offset {
                    if phase.depth < maxDepth {
                        phaseChangeTo(.rampUp(phase.depth + 1))
                    } else {
                        phaseChangeTo(.stable(maxDepth))
                    }
                }
            case .throttled(let depth):
                #if DEBUG
                assert(pendingUnflushedCallbacks == 0, "pendingUnflushedCallbacks is \(pendingUnflushedCallbacks) instead of expected value of 0.")
                #endif
                // If throttled, DON'T ramp up again. Stability / Reliability > Speed.
                phaseChangeTo(.stable(depth))
            case .stable(let depth):
                break // Nothing to do here.
            }
            
            lastReceivedOffset = max(lastReceivedOffset, UInt64(offset))
        } else {
            // Offset Mismatch.
            // (the offset / Data sent to the device does not match the response)
            
            assert(expectedReturnOffsets.count <= phase.depth)
            if !expectedReturnOffsets.isEmpty {
                expectedReturnOffsets.removeFirst()
            }
            
            guard pendingUnflushedCallbacks == 0 else {
                pendingUnflushedCallbacks -= 1
                // When a pipeline flush is needed, it usually involved a dropped packet from the
                // target device (aka 'DFU ghosting' event), so our autoRetry will kick in after
                // the timeout and it might advance th offset on ocassion. That's why we watch
                // out for this scenario within a pipeline flush event.
                lastReceivedOffset = max(lastReceivedOffset, offset)
                return
            }
            
            // Check firmware update offsets are advancing.
            let isPipelineFlushNeeded = offset == lastReceivedOffset
            if isPipelineFlushNeeded {
                pendingUnflushedCallbacks = expectedReturnOffsets.count
                
                // We need to clear our current offsets and start over.
                // If we don't do this, the next call on pipelinedSend() will start from a wrong
                // offset far above what the device is going to reply with, causing an endless
                // loop of us sending Data from the wrong starting (offset) point.
                expectedReturnOffsets.removeAll()
                
                // Throttle down if possible to improve reliability.
                // A likely cause for needing this pipeline flush even is that the target device
                // cannot handle so many writes in parallel.
                if let throttledState = phase.throttledDown() {
                    phaseChangeTo(throttledState)
                }
            }
            
            lastReceivedOffset = offset
            
            // All of our previous 'sends' are invalid.
            // Wait for all of them to return and then continue.
            guard expectedReturnOffsets.isEmpty else {
                return
            }
        }
        expectedReturnOffsets.removeAll(where: { $0 <= offset })
    }
    
    // MARK: allPacketsReceived()
    
    public func allPacketsReceived() -> Bool {
        return expectedReturnOffsets.isEmpty
    }
}

// MARK: - Internal

extension McuMgrUploadPipeline {
    
    mutating func phaseChangeTo(_ newPhase: Phase) {
        phase = newPhase
        switch newPhase {
        case .start:
            log("Pipeline start (depth = \(newPhase.depth)) with a max. depth of \(maxDepth)")
        case .rampUp(let depth):
            log("Pipeline ramping up (new depth = \(depth))")
            (transport as? McuMgrBleTransport)?.numberOfParallelWrites = phase.depth
        case .throttled(let depth):
            log("Pipeline throttling down (reduced depth = \(depth))")
            (transport as? McuMgrBleTransport)?.numberOfParallelWrites = phase.depth
        case .stable(let depth):
            log("Pipeline stabilised at depth \(depth)")
        }
    }
    
    func log(_ message: String) {
        logDelegate?.log(message, ofCategory: .transport, atLevel: .debug)
    }
}
