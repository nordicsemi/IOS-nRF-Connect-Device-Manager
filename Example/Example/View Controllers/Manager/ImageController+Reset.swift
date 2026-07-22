//
//  ImageController+Reset.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 21/07/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import iOSMcuManagerLibrary

extension ImageController {
    
    // MARK: Section
    
    enum ResetSectionRow: Int, RawRepresentable, CaseIterable {
        case firmwareLoaderSelector
        case advertiserName
        case resetCommandButton
    }
    
    // MARK: resetSectionCell(for:)
    
    func resetSectionCell(for row: ResetSectionRow?) -> UITableViewCell {
        switch row {
        case .firmwareLoaderSelector:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "resetFirmwareLoaderSwitch")
            cell.selectionStyle = .none
            
            cell.textLabel?.text = "Switch to Firmware Loader Mode"
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping
            
            let fwLoaderUISwitch = UISwitch()
            fwLoaderUISwitch.isOn = fwLoaderSwitchValue
            fwLoaderUISwitch.addTarget(self, action: #selector(updateFirmwareLoaderSwitch), for: .valueChanged)
            fwLoaderUISwitch.onTintColor = .nordic
            cell.accessoryView = fwLoaderUISwitch
            resetFwLoaderSwitch = fwLoaderUISwitch
            
            return cell
        case .advertiserName:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "resetAdvertiserName")
            cell.selectionStyle = .none
            
            let advNameLabel = UILabel()
            advNameLabel.text = "Adv. Name"
            advNameLabel.textColor = fwLoaderSwitchValue ? .primary : .secondary
            advNameLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(advNameLabel)
            
            let advNameTextField = UITextField()
            advNameTextField.text = fwLoaderAdvName
            advNameTextField.placeholder = "Defaults to 'FL_[HH][mm][ss]'"
            advNameTextField.textAlignment = .right
            advNameTextField.borderStyle = .roundedRect
            advNameTextField.keyboardType = .default
            advNameTextField.returnKeyType = .done
            advNameTextField.autocapitalizationType = .words
            advNameTextField.delegate = self
            advNameTextField.translatesAutoresizingMaskIntoConstraints = false
            advNameTextField.addTarget(self, action: #selector(firmwareLoaderNameChanged), for: .valueChanged)
            advNameTextField.addTarget(self, action: #selector(firmwareLoaderNameChanged), for: .editingChanged)
            cell.contentView.addSubview(advNameTextField)
            resetAdvName = advNameTextField
            
            let bootModeLabel = UILabel()
            bootModeLabel.text = "Boot Mode = '\(fwLoaderSwitchValue ? "1" : "0")'"
            bootModeLabel.textColor = .secondary
            bootModeLabel.font = .monospacedSystemFont(ofSize: 12.0, weight: .regular)
            bootModeLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(bootModeLabel)
            
            NSLayoutConstraint.activate([
                advNameLabel.firstBaselineAnchor.constraint(equalTo: advNameTextField.firstBaselineAnchor),
                advNameLabel.leadingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.leadingAnchor, constant: 14.0),
                
                advNameTextField.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8.0),
                advNameTextField.leadingAnchor.constraint(equalTo: advNameLabel.trailingAnchor, constant: 8.0),
                advNameTextField.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -12.0),
                
                bootModeLabel.topAnchor.constraint(equalTo: advNameTextField.bottomAnchor, constant: 8.0),
                bootModeLabel.trailingAnchor.constraint(equalTo: advNameTextField.trailingAnchor),
                
                cell.contentView.bottomAnchor.constraint(equalTo: bootModeLabel.bottomAnchor, constant: 8.0)
            ])
            
            return cell
        case .resetCommandButton:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "resetButton")
            cell.selectionStyle = .none
            
            let resetCommandResetButton = UIButton()
            resetCommandResetButton.setTitle("Send Reset Command", for: .normal)
            resetCommandResetButton.setTitleColor(.red, for: .normal)
            resetCommandResetButton.setTitleColor(.red.withAlphaComponent(0.5), for: .disabled)
            resetCommandResetButton.addTarget(self, action: #selector(sendResetCommand), for: .touchUpInside)
            resetCommandResetButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            resetCommandResetButton.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(resetCommandResetButton)
            resetButton = resetCommandResetButton
            
            NSLayoutConstraint.activate([
                resetCommandResetButton.topAnchor.constraint(equalToSystemSpacingBelow: cell.contentView.topAnchor, multiplier: 1.0),
                resetCommandResetButton.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                
                cell.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: resetCommandResetButton.bottomAnchor, multiplier: 1.0)
            ])
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: @objc updateFirmwareLoaderSwitch(_:)
    
    @objc func updateFirmwareLoaderSwitch(_ sender: UISwitch) {
        fwLoaderSwitchValue = sender.isOn
        tableView.reloadSections(IndexSet([Section.advancedReset.rawValue]), with: .none)
    }
    
    // MARK: @objc firmwareLoaderNameChanged(_:)
    
    @objc func firmwareLoaderNameChanged(_ sender: UITextField) {
        fwLoaderAdvName = sender.text
    }
    
    // MARK: @objc sendResetCommand(_:)
    
    @objc func sendResetCommand(_ sender: UIButton) {
        callReset(with: fwLoaderSwitchValue ? .bootloader : .normal)
    }
    
    // MARK: callReset(with:)
    
    private func callReset(with mode: DefaultManager.ResetBootMode) {
        Task {
            disableActionableButtons()
            guard mode == .bootloader else {
                do {
                    _ = try await defaultManager.reset(bootMode: mode)
                } catch {}
                updateActionableButtonsState()
                return
            }
            
            let name: String! = (fwLoaderAdvName?.hasItems ?? false) ?
                fwLoaderAdvName : settingsManager.generateNewAdvertisingName()
            do {
                _ = try await settingsManager.setFirmwareLoaderAdvertisingName(name)
                _ = try await defaultManager.reset(bootMode: mode)
            } catch {}
            
            updateActionableButtonsState()
        }
    }
}

// MARK: - UITextFieldDelegate

extension ImageController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
