//
//  ImageController+Images.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 09/07/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import iOSMcuManagerLibrary

extension ImageController {
    
    // MARK: Section
    
    enum ImagesSectionRow: Int, RawRepresentable, CaseIterable {
        case output
        case buttons
    }
    
    // MARK: imagesSectionCell(for:)
    
    func imagesSectionCell(for row: ImagesSectionRow?) -> UITableViewCell {
        switch row {
        case .output:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "imagesOutput")
            cell.selectionStyle = .none
            
            if imagesTextLabel.superview != nil {
                imagesTextLabel.removeFromSuperview()
            }
            cell.contentView.addSubview(imagesTextLabel)
            NSLayoutConstraint.activate([
                imagesTextLabel.topAnchor.constraint(equalToSystemSpacingBelow: cell.contentView.topAnchor, multiplier: 1.0),
                imagesTextLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 14.0),
                imagesTextLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -14.0),
                
                cell.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: imagesTextLabel.bottomAnchor, multiplier: 1.0)
            ])
            return cell
        case .buttons:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "imagesButtons")
            cell.selectionStyle = .none
            
            let readButton = UIButton()
            readButton.setTitle("Read", for: .normal)
            readButton.setTitleColor(.nordic, for: .normal)
            readButton.setTitleColor(.nordic.withAlphaComponent(0.5), for: .disabled)
            readButton.addTarget(self, action: #selector(imageRead), for: .touchUpInside)
            readButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            readButton.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(readButton)
            imagesReadButton = readButton
            
            let testButton = UIButton()
            testButton.setTitle("Test", for: .normal)
            testButton.setTitleColor(.nordic, for: .normal)
            testButton.setTitleColor(.nordic.withAlphaComponent(0.5), for: .disabled)
            testButton.addTarget(self, action: #selector(imageTest), for: .touchUpInside)
            testButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            testButton.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(testButton)
            imagesTestButton = testButton
            
            let confirmButton = UIButton()
            confirmButton.setTitle("Confirm", for: .normal)
            confirmButton.setTitleColor(.nordic, for: .normal)
            confirmButton.setTitleColor(.nordic.withAlphaComponent(0.5), for: .disabled)
            confirmButton.addTarget(self, action: #selector(imageConfirm), for: .touchUpInside)
            confirmButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            confirmButton.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(confirmButton)
            imagesConfirmButton = confirmButton
            
            let eraseButton = UIButton()
            eraseButton.setTitle("Erase", for: .normal)
            eraseButton.setTitleColor(.red, for: .normal)
            eraseButton.setTitleColor(.red.withAlphaComponent(0.5), for: .disabled)
            eraseButton.addTarget(self, action: #selector(imageErase), for: .touchUpInside)
            eraseButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            eraseButton.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(eraseButton)
            imagesEraseButton = eraseButton
            
            NSLayoutConstraint.activate([
                eraseButton.topAnchor.constraint(equalToSystemSpacingBelow: cell.contentView.topAnchor, multiplier: 1.0),
                eraseButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -14.0),
                
                confirmButton.firstBaselineAnchor.constraint(equalTo: eraseButton.firstBaselineAnchor),
                confirmButton.trailingAnchor.constraint(equalTo: eraseButton.leadingAnchor, constant: -16.0),
                
                testButton.firstBaselineAnchor.constraint(equalTo: confirmButton.firstBaselineAnchor),
                testButton.trailingAnchor.constraint(equalTo: confirmButton.leadingAnchor, constant: -16.0),
                
                readButton.firstBaselineAnchor.constraint(equalTo: eraseButton.firstBaselineAnchor),
                readButton.trailingAnchor.constraint(equalTo: testButton.leadingAnchor, constant: -16.0),
                
                cell.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: eraseButton.bottomAnchor, multiplier: 1.0)
            ])
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: @objc imageRead(_:)
    
    @IBAction func imageRead(_ sender: UIButton) {
        Task {
            disableActionableButtons()
            
            switch await requestBootloaderIfNecessary() {
            case .suit:
                do {
                    let response = try await suitManager.listManifest()
                    handle(suitListResponse: response, nil)
                } catch {
                    handle(suitListResponse: nil, error)
                }
            case .mcuboot, .unknown:
                do {
                    let response = try await imageManager.list()
                    handle(response, nil)
                } catch {
                    handle(nil, error)
                }
            }
        }
    }
    
    // MARK: @objc imageTest(_:)
    
    @IBAction func imageTest(_ sender: UIButton) {
        Task {
            guard let imageHash = await selectImageCore() else { return }
            disableActionableButtons()
            do {
                let response = try await imageManager.test(hash: imageHash)
                handle(response, nil)
            } catch {
                handle(nil, error)
            }
        }
    }
    
    // MARK: @objc imageConfirm(_:)
    
    @IBAction func imageConfirm(_ sender: UIButton) {
        Task {
            disableActionableButtons()
            
            switch await requestBootloaderIfNecessary() {
            case .suit:
                do {
                    let response = try await suitManager.processRecentlyUploadedEnvelope()
                    if response.rc != .ok {
                        setImagesText(response.rc.localizedDescription, color: .systemRed, readEnabled: true)
                    } else {
                        setImagesText("Success!", color: .primary, readEnabled: true)
                    }
                } catch {
                    setImagesText(error.localizedDescription, color: .systemRed, readEnabled: true)
                }
            case .mcuboot, .unknown:
                guard let imageHash = await selectImageCore() else { return }
                do {
                    readImagesResponse = try await imageManager.confirm(hash: imageHash)
                    handle(readImagesResponse, nil)
                } catch {
                    handle(nil, error)
                }
            }
        }
    }
    
    // MARK: @objc imageErase(_:)
    
    @IBAction func imageErase(_ sender: UIButton) {
        Task {
            do {
                switch await requestBootloaderIfNecessary() {
                case .suit:
                    disableActionableButtons()
                    let response = try await suitManager.cleanup()
                    if response.rc != .ok {
                        setImagesText(response.rc.description, color: .systemRed, readEnabled: true)
                    } else {
                        setImagesText("Cleanup Successful", color: .primary, readEnabled: true)
                    }
                case .mcuboot, .unknown:
                    guard let unconfirmedSlot = await selectUnconfirmedImageSlot() else { return }
                    disableActionableButtons()
                    let response = try await imageManager.erase(image: Int(unconfirmedSlot.0),
                                                                slot: Int(unconfirmedSlot.1))
                    if response.rc != .ok {
                        setImagesText(response.rc.description, color: .systemRed, readEnabled: true)
                    } else {
                        imageRead(sender)
                    }
                }
            } catch {
                setImagesText(error.localizedDescription, color: .systemRed, readEnabled: true)
            }
        }
    }
    
    // MARK: selectImageCore(callback:)
    
    private func selectImageCore() async -> [UInt8]? {
        guard let responseImages = readImagesResponse?.images else { return nil }
        let unconfirmedImages = responseImages.filter({ !$0.confirmed })
        if let singleUnconfirmed = unconfirmedImages.first, unconfirmedImages.count == 1 {
            return (singleUnconfirmed.hash)
        }
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<[UInt8]?, Never>) in
            let alertController = buildSelectImageController() {
                continuation.resume(returning: nil)
            }
            
            for image in unconfirmedImages {
                let title = "Image \(image.image), slot \(image.slot)"
                alertController.addAction(UIAlertAction(title: title, style: .default) { action in
                    continuation.resume(returning: image.hash)
                })
            }
            present(alertController, animated: true)
        }
    }
    
    // MARK: selectUnconfirmedImageSlot
    
    private func selectUnconfirmedImageSlot() async -> (UInt64, UInt64)? {
        guard let responseImages = readImagesResponse?.images else { return nil }
        let unconfirmedImages = responseImages.filter({ !$0.confirmed })
        if let singleUnconfirmed = unconfirmedImages.first, unconfirmedImages.count == 1 {
            return (singleUnconfirmed.image, singleUnconfirmed.slot)
        }
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<(UInt64, UInt64)?, Never>) in
            let alertController = buildSelectImageController() {
                continuation.resume(returning: nil)
            }
            
            for image in unconfirmedImages {
                let title = "Image \(image.image), slot \(image.slot)"
                alertController.addAction(UIAlertAction(title: title, style: .default) { action in
                    continuation.resume(returning: (image.image, image.slot))
                })
            }
            present(alertController, animated: true)
        }
    }
    
    // MARK: handle(suitListResponse:error:)
    
    private func handle(suitListResponse response: SuitListResponse?, _ error: Error?) {
        if let response {
            switch response.result {
            case .success:
                imagesTestButton?.isEnabled = false
                imagesConfirmButton?.isEnabled = true
                imagesEraseButton?.isEnabled = true
                setImagesText(getInfo(from: response), color: .primary, readEnabled: true)
            case .failure(let error):
                setImagesText(error.localizedDescription, color: .systemRed, readEnabled: true)
            }
        } else {
            imagesReadButton?.isEnabled = true
            imagesTextLabel.textColor = .systemRed
            if let error {
                imagesTextLabel.text = error.localizedDescription
            } else {
                imagesTextLabel.text = "Empty Response"
            }
        }
        
        tableView.reloadSections(IndexSet([Section.advancedImages.rawValue]), with: .none)
    }
    
    // MARK: handle(response:error:)
    
    internal func handle(_ response: McuMgrImageStateResponse?, _ error: Error?) {
        readImagesResponse = response
        if let response {
            switch response.result {
            case .success:
                setImagesText(getInfo(from: response), color: .primary, readEnabled: true)
            case .failure(let error):
                setImagesText(error.localizedDescription, color: .systemRed, readEnabled: true)
            }
        } else { // no response
            imagesTextLabel.textColor = .systemRed
            if let error {
                imagesTextLabel.text = error.localizedDescription
            } else {
                imagesTextLabel.text = "Empty response"
            }
        }
        
        updateActionableButtonsState()
    }
    
    // MARK: getInfo()
    
    private func getInfo(from response: SuitListResponse) -> String {
        let roles = response.roles ?? []
        let states = response.states ?? []
        assert(roles.count == states.count)
        
        var info = ""
        for (role, state) in zip(roles, states) {
            let classString = (try? state.classUUID()?.uuidString) ?? "N/A"
            let vendorString = (try? state.vendorUUID()?.uuidString) ?? "N/A"
            let digestString = Data(state.digest ?? []).hexEncodedString(options: [.prepend0x, .upperCase])
            info += "• Role: \(role.description)\n  Sequence Number: \(state.sequenceNumberHexString() ?? "N/A")\n  Class: \(classString)\n  Vendor: \(vendorString)\n  Downgrade Policy: \(state.downgradePreventionPolicy?.description ?? "N/A")\n  Independent Update Policy: \(state.independentUpdateabilityPolicy?.description ?? "N/A")\n  Signature Verification: \(state.signatureCheck?.description ?? "N/A")\n  Verification Policy: \(state.signatureVerificationPolicy?.description ?? "N/A")\n  Digest: \(digestString)\n  Digest Algorithm: \(state.digestAlgorithm?.description ?? "N/A")\n  Version: \(state.semanticVersionString() ?? "N/A")\n\n"
        }
        return info
    }
    
    private func getInfo(from response: McuMgrImageStateResponse) -> String {
        let images = response.images ?? []
        var info = "Split status: \(response.splitStatus ?? 0)"
        
        for image in images {
            info += "\n\nImage: \(image.image), Slot: \(image.slot)\n" +
                "• Version: \(image.version ?? "Unknown")\n" +
                "• Hash: \(Data(image.hash).hexEncodedString(options: .upperCase))\n" +
                "• Flags: "
            if image.bootable {
                info += "Bootable, "
            }
            if image.pending {
                info += "Pending, "
            }
            if image.confirmed {
                info += "Confirmed, "
            }
            if image.active {
                info += "Active, "
            }
            if image.permanent {
                info += "Permanent, "
            }
            if image.compressed {
                info += "Compressed, "
            }
            if !image.bootable && !image.pending && !image.confirmed && !image.active && !image.permanent && !image.compressed {
                info += "None, "
            } else {
                info = String(info.dropLast(2))
            }
        }
        return info
    }
    
    // MARK: setImagesText(_:color:readEnabled)
    
    private func setImagesText(_ text: String, color: UIColor, readEnabled: Bool) {
        imagesTextLabel.text = text
        imagesTextLabel.textColor = color
        imagesReadButton?.isEnabled = readEnabled
        
        tableView.reloadSections(IndexSet([Section.advancedImages.rawValue]), with: .none)
    }
}
