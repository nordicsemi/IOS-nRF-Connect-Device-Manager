//
//  ImageController+Settings.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 21/07/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import iOSMcuManagerLibrary

extension ImageController {
    
    // MARK: Section
    
    enum SettingsSectionRow: Int, RawRepresentable, CaseIterable {
        case text
        case eraseSettingsButton
    }
    
    // MARK: settingsSectionCell(for:)
    
    func settingsSectionCell(for row: SettingsSectionRow?) -> UITableViewCell {
        switch row {
        case .text:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "settingsText")
            cell.selectionStyle = .none
            cell.textLabel?.text = "Tap FACTORY RESET button to erase application storage."
            cell.textLabel?.textColor = .secondary
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping
            return cell
        case .eraseSettingsButton:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "settingsEraseButton")
            cell.selectionStyle = .none
            
            let factoryEraseButton = UIButton()
            factoryEraseButton.setTitle("Factory Reset", for: .normal)
            factoryEraseButton.setTitleColor(.red, for: .normal)
            factoryEraseButton.setTitleColor(.red.withAlphaComponent(0.5), for: .disabled)
            factoryEraseButton.addTarget(self, action: #selector(settingsErase), for: .touchUpInside)
            factoryEraseButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            factoryEraseButton.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(factoryEraseButton)
            settingsEraseButton = factoryEraseButton
            
            NSLayoutConstraint.activate([
                factoryEraseButton.topAnchor.constraint(equalToSystemSpacingBelow: cell.contentView.topAnchor, multiplier: 1.0),
                factoryEraseButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -14.0),
                
                cell.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: factoryEraseButton.bottomAnchor, multiplier: 1.0)
            ])
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: @objc settingsErase(_:)
    
    @IBAction func settingsErase(_ sender: UIButton) {
        Task {
            disableActionableButtons()
            
            do {
                let _ = try await basicManager.eraseAppSettings()
            } catch {
                handle(nil, error)
            }
            
            updateActionableButtonsState(for: .none)
        }
    }
}
