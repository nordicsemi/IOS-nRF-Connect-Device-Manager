//
//  MockDevice.swift
//  iOSMcuManagerLibraryTests
//
//  Created by Luka Dulcic on 03/11/26.
//

import Foundation
import SwiftCBOR
import iOSMcuManagerLibrary

// MARK: - MockDevice

/**
 Emulates the SMP server of a Zephyr device with MCUboot: the image state command, the reset and the boot that follows it.
 
 A confirm marks the image to be booted permanently, as Zephyr does by default also for an image that is not running. McuMgr Parameters, Bootloader Info and all other commands are not supported.
 */
final class MockDevice: McuMgrTransport {
    
    // MARK: Slot
    
    struct Slot {
        let image: Int
        let slot: Int
        let hash: Data
        var active: Bool
        var confirmed: Bool
        var pending = false
        var permanent = false
    }
    
    // MARK: Properties
    
    var mtu: Int! = 498
    let mode: McuMgrTransportMode = .default
    
    /// Answers the list request after the reset with this return code instead of the images.
    var listErrorAfterReset: McuMgrReturnCode?
    /// Fails the list request after the reset with this error instead of answering it.
    var listFailureAfterReset: Error?
    /// Leaves the images out of the response to the list request after the reset.
    var listImagesAfterReset = true
    /// If set, the list request after the reset waits for ``answerHeldList()``, and this is called instead.
    var onListHeldAfterReset: (() -> Void)?
    
    /// The hashes of all received confirm requests, in order.
    var confirmedHashes: [Data] {
        queue.sync { confirmRequests }
    }
    
    private var slots: [Slot]
    private let slotsAfterReset: [Slot]
    private var reset = false
    private var heldList: (() -> Void)?
    private var confirmRequests: [Data] = []
    /// Only used on the main queue, like the observers of the BLE transport.
    private var observers: [ConnectionObserver] = []
    private let queue = DispatchQueue(label: "MockDevice")
    
    private static let stateCommand: UInt8 = 0
    private static let resetCommand: UInt8 = 5
    
    // MARK: Init
    
    /**
     - parameter slots: The image slots before the upgrade.
     - parameter slotsAfterReset: The image slots after a reset with an image pending for test, as the bootloader left them.
     */
    init(slots: [Slot], slotsAfterReset: [Slot]) {
        self.slots = slots
        self.slotsAfterReset = slotsAfterReset
    }
    
    // MARK: API
    
    /// Answers the list request after the reset held because of ``onListHeldAfterReset``.
    func answerHeldList() {
        queue.async { [self] in
            heldList?()
            heldList = nil
        }
    }
    
    // MARK: McuMgrTransport
    
    func getScheme() -> McuMgrScheme {
        return .ble
    }
    
    func switchMode(to newMode: McuMgrTransportMode, with modeParameter: Any?) throws {
        // Not used in these tests.
    }
    
    func send<T: McuMgrResponse>(data: Data, timeout: Int, autoRetry: Bool, callback: @escaping McuMgrCallback<T>) {
        queue.async { [self] in
            let header: McuMgrHeader
            let request: CBOR?
            do {
                header = try McuMgrHeader(data: data)
                request = try CBOR.decode([UInt8](data.dropFirst(McuMgrHeader.HEADER_LENGTH)))
            } catch {
                callback(nil, error)
                return
            }
            
            let respond = { (payload: [String: CBOR]) in
                do {
                    let response: T = try McuMgrResponse.buildResponse(scheme: .ble, data: Self.packet(answering: header, with: payload))
                    callback(response, nil)
                } catch {
                    callback(nil, error)
                }
            }
            
            let group: UInt16 = header.groupId
            let command: UInt8 = header.commandId
            let op: UInt8 = header.op
            switch (group, command) {
            case (McuMgrGroup.OS.rawValue, Self.resetCommand):
                respond([:])
                resetDevice()
            case (McuMgrGroup.image.rawValue, Self.stateCommand) where op == McuMgrOperation.read.rawValue:
                list(respond: respond, fail: { callback(nil, $0) })
            case (McuMgrGroup.image.rawValue, Self.stateCommand):
                respond(changeState(request))
            default:
                respond(["rc": CBOR.unsignedInt(McuMgrReturnCode.unsupported.rawValue)])
            }
        }
    }
    
    func connect(_ callback: @escaping ConnectionCallback) {
        // Like the BLE transport, which connects with the next request.
        DispatchQueue.main.async {
            callback(.deferred)
        }
    }
    
    func close() {
        // Nothing to release.
    }
    
    func addObserver(_ observer: ConnectionObserver) {
        observers.append(observer)
    }
    
    func removeObserver(_ observer: ConnectionObserver) {
        observers.removeAll { $0 === observer }
    }
}

// MARK: - Private

private extension MockDevice {
    
    func list(respond: @escaping ([String: CBOR]) -> Void, fail: @escaping (Error) -> Void) {
        guard reset else {
            respond(images(slots))
            return
        }
        let answer = { [self] in
            if let listFailureAfterReset {
                fail(listFailureAfterReset)
            } else if let listErrorAfterReset {
                respond(["rc": CBOR.unsignedInt(listErrorAfterReset.rawValue)])
            } else if listImagesAfterReset {
                respond(images(slots))
            } else {
                respond([:])
            }
        }
        guard let onListHeldAfterReset else {
            answer()
            return
        }
        heldList = answer
        onListHeldAfterReset()
    }
    
    /// Test marks the image with the given hash pending. Confirm marks the running image confirmed, and any other image pending and permanent.
    func changeState(_ request: CBOR?) -> [String: CBOR] {
        guard case let CBOR.byteString(hash)? = request?["hash"] else {
            return ["rc": CBOR.unsignedInt(McuMgrReturnCode.inValue.rawValue)]
        }
        let confirm = request?["confirm"] == CBOR.boolean(true)
        if confirm {
            confirmRequests.append(Data(hash))
        }
        guard let i = slots.firstIndex(where: { $0.hash == Data(hash) }) else {
            return ["rc": CBOR.unsignedInt(McuMgrReturnCode.inValue.rawValue)]
        }
        if !confirm {
            slots[i].pending = true
        } else if slots[i].active {
            slots[i].confirmed = true
        } else {
            slots[i].pending = true
            slots[i].permanent = true
        }
        return images(slots)
    }
    
    /// The connection drops and the device reboots. It boots into ``slotsAfterReset`` only if an image is pending for test, and into the same images otherwise.
    func resetDevice() {
        reset = true
        if slots.contains(where: { $0.pending }) {
            slots = slotsAfterReset
        }
        DispatchQueue.main.async { [self] in
            for observer in observers {
                observer.transport(self, didChangeStateTo: .disconnected(expected: true))
            }
        }
    }
    
    func images(_ slots: [Slot]) -> [String: CBOR] {
        return ["images": CBOR.array(slots.map { slot in
            CBOR.map([
                "image": CBOR.unsignedInt(UInt64(slot.image)),
                "slot": CBOR.unsignedInt(UInt64(slot.slot)),
                "hash": CBOR.byteString([UInt8](slot.hash)),
                "bootable": CBOR.boolean(true),
                "pending": CBOR.boolean(slot.pending),
                "confirmed": CBOR.boolean(slot.confirmed),
                "active": CBOR.boolean(slot.active),
                "permanent": CBOR.boolean(slot.permanent)
            ])
        })]
    }
    
    static func packet(answering request: McuMgrHeader, with payload: [String: CBOR]) -> Data {
        let body = CBOR.encode(payload)
        let header = McuMgrHeader.build(version: request.version, op: request.op + 1, flags: 0,
                                        len: UInt16(body.count), group: request.groupId,
                                        seq: request.sequenceNumber, id: request.commandId)
        return Data(header + body)
    }
}
