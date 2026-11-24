//
//  TestAndConfirmTests.swift
//  iOSMcuManagerLibraryTests
//
//  Created by Luka Dulcic on 03/11/26.
//

import XCTest
import iOSMcuManagerLibrary

// MARK: - TestAndConfirmTests

/**
 Runs Test and Confirm upgrades against a ``MockDevice``. The new images are already in the secondary slots, so each upgrade goes straight to the test, the reset and the confirmation.
 */
final class TestAndConfirmTests: XCTestCase {
    
    private let oldImage = Data(repeating: 1, count: 32)
    private let newImage = Data(repeating: 2, count: 32)
    private let oldNetImage = Data(repeating: 3, count: 32)
    private let newNetImage = Data(repeating: 4, count: 32)
    
    // MARK: One Image
    
    func testNewImageIsConfirmedWhenItRuns() {
        let device = MockDevice(slots: uploaded(newImage, over: oldImage),
                                slotsAfterReset: testBoot(newImage, old: oldImage))
        
        XCTAssertNil(upgrade(device, to: [newImage]))
        XCTAssertEqual(device.confirmedHashes, [newImage])
    }
    
    func testNewImageIsConfirmedWhenItRunsFromTheSecondarySlot() {
        // In Direct XIP mode, the new image runs from the slot it was uploaded to.
        let device = MockDevice(slots: uploaded(newImage, over: oldImage), slotsAfterReset: [
            slot(0, oldImage, active: false, confirmed: true),
            slot(1, newImage, active: true, confirmed: false)
        ])
        
        XCTAssertNil(upgrade(device, to: [newImage]))
        XCTAssertEqual(device.confirmedHashes, [newImage])
    }
    
    func testNothingIsConfirmedWhenTheDeviceRevertedToThePreviousImage() {
        let device = MockDevice(slots: uploaded(newImage, over: oldImage),
                                slotsAfterReset: reverted(newImage, old: oldImage))
        
        let error = upgrade(device, to: [newImage])
        
        XCTAssertEqual(device.confirmedHashes, [])
        XCTAssertEqual(error?.localizedDescription, "The new image is not active after the reset (image 0)")
        guard case .uploadedImageNotActive(image: 0, slot: 1)? = error as? FirmwareUpgradeError else {
            return XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
    func testNothingIsConfirmedWhenTheNewImageIsNotOnTheDevice() {
        // MCUboot may erase an image that fails validation, and in Direct XIP mode one that failed to boot.
        let device = MockDevice(slots: uploaded(newImage, over: oldImage),
                                slotsAfterReset: [slot(0, oldImage, active: true)])
        
        let error = upgrade(device, to: [newImage])
        
        XCTAssertEqual(device.confirmedHashes, [])
        XCTAssertEqual(error?.localizedDescription, "The new image was not found after the reset (image 0)")
        guard case .uploadedImageNotFound(image: 0, slot: 1)? = error as? FirmwareUpgradeError else {
            return XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
    func testNothingIsConfirmedWhenTheNewImageRunsAsAnotherImageIndex() {
        let device = MockDevice(slots: uploaded(newImage, over: oldImage),
                                slotsAfterReset: reverted(newImage, old: oldImage) + [
            slot(0, newImage, active: true, confirmed: false, image: 1)
        ])
        
        let error = upgrade(device, to: [newImage])
        
        XCTAssertEqual(device.confirmedHashes, [])
        guard case .uploadedImageNotActive(image: 0, slot: 1)? = error as? FirmwareUpgradeError else {
            return XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
    // MARK: List After the Reset
    
    func testUpgradeFailsWhenTheListAfterTheResetReturnsAnError() {
        let device = MockDevice(slots: uploaded(newImage, over: oldImage),
                                slotsAfterReset: testBoot(newImage, old: oldImage))
        device.listErrorAfterReset = .unknown
        
        let error = upgrade(device, to: [newImage])
        
        guard case .returnCode(let rc)? = error as? McuMgrError else {
            return XCTFail("Unexpected error: \(String(describing: error))")
        }
        XCTAssertEqual(rc, .unknown)
        XCTAssertEqual(device.confirmedHashes, [])
    }
    
    func testUpgradeFailsWhenTheListAfterTheResetFails() {
        let device = MockDevice(slots: uploaded(newImage, over: oldImage),
                                slotsAfterReset: testBoot(newImage, old: oldImage))
        device.listFailureAfterReset = McuMgrTransportError.sendTimeout
        
        let error = upgrade(device, to: [newImage])
        
        XCTAssertEqual(error as? McuMgrTransportError, .sendTimeout)
        XCTAssertEqual(device.confirmedHashes, [])
    }
    
    func testUpgradeFailsWhenTheListAfterTheResetHasNoImages() {
        let device = MockDevice(slots: uploaded(newImage, over: oldImage),
                                slotsAfterReset: testBoot(newImage, old: oldImage))
        device.listImagesAfterReset = false
        
        let error = upgrade(device, to: [newImage])
        
        guard case .invalidResponse? = error as? FirmwareUpgradeError else {
            return XCTFail("Unexpected error: \(String(describing: error))")
        }
        XCTAssertEqual(device.confirmedHashes, [])
    }
    
    // MARK: Two Images
    
    func testNothingIsConfirmedWhenAnotherImageOfTheUpgradeWasReverted() {
        // Image 1 was reverted on its own, so image 0 must not be confirmed either.
        let device = MockDevice(
            slots: uploaded(newImage, over: oldImage) + uploaded(newNetImage, over: oldNetImage, image: 1),
            slotsAfterReset: testBoot(newImage, old: oldImage) + reverted(newNetImage, old: oldNetImage, image: 1)
        )
        
        let error = upgrade(device, to: [newImage, newNetImage])
        
        XCTAssertEqual(device.confirmedHashes, [])
        guard case .uploadedImageNotActive(image: 1, slot: 1)? = error as? FirmwareUpgradeError else {
            return XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
    func testNewImagesAreConfirmedWhenTheyRun() {
        let device = MockDevice(
            slots: uploaded(newImage, over: oldImage) + uploaded(newNetImage, over: oldNetImage, image: 1),
            slotsAfterReset: testBoot(newImage, old: oldImage) + testBoot(newNetImage, old: oldNetImage, image: 1)
        )
        
        XCTAssertNil(upgrade(device, to: [newImage, newNetImage]))
        XCTAssertEqual(device.confirmedHashes, [newImage, newNetImage])
    }
    
    // MARK: Cancel and Pause
    
    func testNothingIsConfirmedWhenTheUpgradeIsCancelledDuringTheCheck() {
        let device = MockDevice(slots: uploaded(newImage, over: oldImage),
                                slotsAfterReset: testBoot(newImage, old: oldImage))
        let listed = expectation(description: "The images are listed after the reset")
        device.onListHeldAfterReset = { listed.fulfill() }
        let cancelled = expectation(description: "The upgrade is cancelled")
        cancelled.assertForOverFulfill = false
        let delegate = UpgradeDelegate()
        delegate.onCancel = { cancelled.fulfill() }
        
        let manager = start(device, to: [newImage], reportingTo: delegate)
        wait(for: [listed], timeout: 5)
        manager.cancel()
        device.answerHeldList()
        
        wait(for: [cancelled], timeout: 5)
        XCTAssertEqual(device.confirmedHashes, [], "A cancelled upgrade must not confirm the image")
    }
    
    func testNothingIsConfirmedUntilThePausedUpgradeResumes() {
        let device = MockDevice(slots: uploaded(newImage, over: oldImage),
                                slotsAfterReset: testBoot(newImage, old: oldImage))
        let listed = expectation(description: "The images are listed after the reset")
        device.onListHeldAfterReset = { listed.fulfill() }
        let confirming = expectation(description: "The upgrade moves on to the confirmation")
        let ended = expectation(description: "The upgrade ends")
        let delegate = UpgradeDelegate()
        delegate.onStateChange = { state in
            if state == .confirm {
                confirming.fulfill()
            }
        }
        delegate.onEnd = { ended.fulfill() }
        
        let manager = start(device, to: [newImage], reportingTo: delegate)
        wait(for: [listed], timeout: 5)
        manager.pause()
        device.answerHeldList()
        
        // The check passes, and the confirmation waits for the upgrade to resume.
        wait(for: [confirming], timeout: 5)
        XCTAssertEqual(device.confirmedHashes, [], "A paused upgrade must not confirm the image")
        
        manager.resume()
        wait(for: [ended], timeout: 5)
        XCTAssertNil(delegate.error)
        XCTAssertEqual(device.confirmedHashes, [newImage])
    }
}

// MARK: - Private

private extension TestAndConfirmTests {
    
    func slot(_ slot: Int, _ hash: Data, active: Bool, confirmed: Bool? = nil,
              image: Int = 0) -> MockDevice.Slot {
        return MockDevice.Slot(image: image, slot: slot, hash: hash, active: active,
                               confirmed: confirmed ?? active)
    }
    
    /// The slots of an image before the upgrade: the previous image runs, and the new one is already uploaded.
    func uploaded(_ new: Data, over old: Data, image: Int = 0) -> [MockDevice.Slot] {
        return [
            slot(0, old, active: true, image: image),
            slot(1, new, active: false, image: image)
        ]
    }
    
    /// The slots of an image after a successful test boot: the new image runs, not confirmed yet, and the previous one stays confirmed in the other slot. Zephyr's image list marks the active slot of every image, so the same goes for image 1.
    func testBoot(_ new: Data, old: Data, image: Int = 0) -> [MockDevice.Slot] {
        return [
            slot(0, new, active: true, confirmed: false, image: image),
            slot(1, old, active: false, confirmed: true, image: image)
        ]
    }
    
    /// The slots of an image after MCUboot reverted the new one. They look as they did before the test.
    func reverted(_ new: Data, old: Data, image: Int = 0) -> [MockDevice.Slot] {
        return uploaded(new, over: old, image: image)
    }
    
    /// Starts a Test and Confirm upgrade to the new images, one for each image index from 0.
    func start(_ device: MockDevice, to hashes: [Data],
               reportingTo delegate: UpgradeDelegate) -> FirmwareUpgradeManager {
        let manager = FirmwareUpgradeManager(transport: device, delegate: delegate)
        let images = hashes.enumerated().map { index, hash in
            ImageManager.Image(image: index, hash: hash, data: hash)
        }
        manager.start(images: images, using: FirmwareUpgradeConfiguration(upgradeMode: .testAndConfirm))
        return manager
    }
    
    /// Runs a Test and Confirm upgrade to the new images and returns its error, or nil when it completed.
    func upgrade(_ device: MockDevice, to hashes: [Data]) -> Error? {
        let ended = expectation(description: "The upgrade ends")
        let delegate = UpgradeDelegate()
        delegate.onEnd = { ended.fulfill() }
        
        let manager = start(device, to: hashes, reportingTo: delegate)
        wait(for: [ended], timeout: 5)
        withExtendedLifetime(manager) {}
        return delegate.error
    }
}

// MARK: - UpgradeDelegate

/// Reports the progress of an upgrade to the test.
private final class UpgradeDelegate: FirmwareUpgradeDelegate {
    
    var onStateChange: ((FirmwareUpgradeState) -> Void)?
    var onEnd: (() -> Void)?
    var onCancel: (() -> Void)?
    /// The error of a failed upgrade.
    private(set) var error: Error?
    
    func upgradeDidStart(controller: FirmwareUpgradeController) {
        // Not needed.
    }
    
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        onStateChange?(newState)
    }
    
    func upgradeDidComplete() {
        onEnd?()
    }
    
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        self.error = error
        onEnd?()
    }
    
    func upgradeDidCancel(state: FirmwareUpgradeState) {
        onCancel?()
    }
    
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        // Not needed.
    }
}
