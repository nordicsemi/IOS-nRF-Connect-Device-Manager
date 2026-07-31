//
//  McuMgrCallbackOoOBuffer.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 29/9/22.
//

import Foundation
import Dispatch
import os.log

// MARK: - McuMgrCallbackOoOBuffer<Key, Value>

/**
 <Key, Value> Out-of-Order Buffer.
 */
public struct McuMgrCallbackOoOBuffer<Key: Hashable & Comparable, Value> {
    
    // MARK: BufferError
    
    public enum BufferError: Error {
        case empty
        case invalidKey(_ key: Key)
        case noValueForKey(_ key: Key)
    }
    
    // MARK: Private
    
    private var internalQueue = DispatchQueue(label: "mcumgr.robbuffer.queue")
    
    private var expectedKeys: [Key] = []
    
    private var outOfOrderKeys: Set<Key> = []
    private var buffer: [Key: Value] = [:]
    private var undeliveredKeys: [Key: KeyCallback] = [:]
    
    // MARK: API
    
    public typealias KeyCallback = ((Value) -> Void)
    
    public weak var logDelegate: McuMgrLogDelegate?
    
    /**
     Required call when a `Key` is now expected, so the buffer can track it.
     
     For example, if you'd like to be able to reorder a sequence of expected
     events, when you know a certain event is expected to happen, you must call
     this function. Subsequent calls to this function should reflect the expected
     order of responses, so for example, if you expect events A, B, C, D, E,
     call in said order.
     
     - Parameter key: the key to begin expecting a ``received(_ value: Value, for key: Key)`` call for.
     - Parameter callback: the specific ``KeyCallback`` attached to the given key.
     */
    mutating public func enqueueKey(_ key: Key, forCallback callback: @escaping KeyCallback) {
        internalQueue.sync {
            expectedKeys.append(key)
            undeliveredKeys[key] = callback
        }
    }
    
    /**
     Required call when a `Value` is received.
     
     It might seem unnecessary to call this if the caller already has the appropriate
     <Key, Value> pair. But what this call does is trigger delivery of all in-order received
     ``Value``(s) if none are pending. So if called with a `Value` for a `Key` we're
     not expecting since it's not the next one (in order), this buffer will wait. Once all
     pending `Key`(s) are received, then the associated ``KeyCallback`` for each key will
     be called.
     
     - Parameter value: the latest `Value` that was received.
     - Parameter key: the specific `Key` attached to the received `Value`.
     - Throws: If there is a logic error caused by invalid buffer use, a ``BufferError``
     will be thrown.
     */
    mutating public func received(_ value: Value, for key: Key) throws {
        try internalQueue.sync {
            guard let i = expectedKeys.firstIndex(where: { $0 == key }) else {
                guard outOfOrderKeys.contains(key) else {
                    throw BufferError.invalidKey(key)
                }
                    
                buffer[key] = value
                log(msg: "Received missing OoO (Out of Order) Key \(key).", atLevel: .debug)
                outOfOrderKeys.remove(key)
                
                if outOfOrderKeys.isEmpty {
                    // Deliver all pending keys.
                    try deliverAllKeysInBuffer()
                } // else wait for missing keys.
                return
            }

            guard let lowestExpectedKey = expectedKeys.first else {
                throw BufferError.empty
            }
            assert(expectedKeys[i] == key)
            buffer[key] = value

            let valueReceivedInOrder = i == 0
            if valueReceivedInOrder {
                expectedKeys.removeFirst()
                try deliverAllKeysInBuffer()
            } else {
                let lowerKeys = expectedKeys.filter({ $0 < key })
                lowerKeys.forEach {
                    outOfOrderKeys.insert($0)
                }
                
                log(msg: "Received Value for Key \(key) OoO (Out of Order). Expected \(lowestExpectedKey) instead.",
                    atLevel: .debug)
                expectedKeys.removeAll(where: { $0 <= key })
                // Wait until we next receive a value.
            }
        }
    }
}

// MARK: - Fileprivate

fileprivate extension McuMgrCallbackOoOBuffer {
    
    // MARK: deliverAllKeysInBuffer()
    
    mutating func deliverAllKeysInBuffer() throws {
        for key in buffer.keys.sorted(by: <) {
            guard let value = buffer.removeValue(forKey: key),
                  let callback = undeliveredKeys.removeValue(forKey: key) else {
                throw BufferError.noValueForKey(key)
            }

            DispatchQueue.main.async {
                callback(value)
            }
        }
    }
    
    // MARK: log(msg:atLevel:)
    
    func log(msg: @autoclosure () -> String, atLevel level: McuMgrLogLevel) {
        if let logDelegate, level >= logDelegate.minLogLevel() {
            logDelegate.log(msg(), ofCategory: .transport, atLevel: level)
        }
    }
}
