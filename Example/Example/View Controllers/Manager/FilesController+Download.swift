//
//  FilesController+Download.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 04/06/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import iOSMcuManagerLibrary

extension FilesController {
    
    // MARK: downloadSectionCell(for:)
    
    func downloadSectionCell(for row: DownloadSectionRow?) -> UITableViewCell {
        switch row {
        case .downloadInput:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "downloadInput")
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.size.width, bottom: 0, right: 0)
            
            if downloadTextField.superview != nil {
                downloadTextField.removeFromSuperview()
            }
            if downloadRecentsButton.superview != nil {
                downloadRecentsButton.removeFromSuperview()
            }
            if downloadActionButton.superview != nil {
                downloadActionButton.removeFromSuperview()
            }
            
            let recents = UserDefaults.standard.array(forKey: Self.recentsKey)
            downloadRecentsButton.isEnabled = recents != nil
            downloadRecentsButton.tintColor = downloadRecentsButton.isEnabled ? .nordic : .secondary
            downloadActionButton.tintColor = .nordic
            
            cell.contentView.addSubview(downloadTextField)
            cell.contentView.addSubview(downloadRecentsButton)
            cell.contentView.addSubview(downloadActionButton)
            NSLayoutConstraint.activate([
                downloadActionButton.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                downloadActionButton.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                
                downloadRecentsButton.topAnchor.constraint(equalTo: downloadActionButton.topAnchor),
                downloadRecentsButton.trailingAnchor.constraint(equalTo: downloadActionButton.leadingAnchor, constant: -8.0),
                
                downloadTextField.topAnchor.constraint(equalTo: downloadActionButton.topAnchor),
                downloadTextField.leadingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.leadingAnchor, constant: 14.0),
                downloadTextField.trailingAnchor.constraint(equalTo: downloadRecentsButton.leadingAnchor, constant: -12.0),
                
                cell.contentView.bottomAnchor.constraint(equalTo: downloadTextField.bottomAnchor, constant: 8.0)
            ])
            return cell
        case .downloadPath:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "downloadPath")
            cell.selectionStyle = .none
            let partition = UserDefaults.standard.string(forKey: FilesController.partitionKey)
                ?? FilesController.defaultPartition
            cell.textLabel?.text = "/\(partition)/\(downloadFilename ?? "")"
            cell.textLabel?.textColor = .secondary
            downloadDestinationLabel = cell.textLabel
            return cell
        case .downloadOutput:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "downloadOutput")
            cell.selectionStyle = .none
            if downloadProgress.superview != nil {
                downloadProgress.removeFromSuperview()
            }
            if downloadResultLabel.superview != nil {
                downloadResultLabel.removeFromSuperview()
            }
            cell.contentView.addSubview(downloadProgress)
            cell.contentView.addSubview(downloadResultLabel)
            
            switch downloadState {
            case .selectFile:
                downloadResultLabel.text = ""
                downloadResultLabel.textColor = .secondary
            case .ready:
                downloadResultLabel.text = "READY"
            case .inProgress(let percentage, _):
                downloadProgress.setProgress(percentage, animated: true)
            case .paused:
                downloadResultLabel.text = "PAUSED"
                downloadResultLabel.textColor = .primary
            case .cancelled:
                downloadResultLabel.text = "CANCELLED"
                downloadResultLabel.textColor = .red
                downloadProgress.setProgress(0.0, animated: false)
            case .error(let error):
                downloadResultLabel.text = "Error: \(error.localizedDescription)"
                downloadResultLabel.textColor = .red
                downloadProgress.setProgress(0.0, animated: false)
            case .completed:
                downloadResultLabel.text = "SUCCESS"
                downloadResultLabel.textColor = .primary
                downloadProgress.setProgress(0.0, animated: false)
            }
            
            NSLayoutConstraint.activate([
                downloadProgress.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                downloadProgress.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                downloadProgress.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                
                downloadResultLabel.topAnchor.constraint(equalTo: downloadProgress.bottomAnchor, constant: 8.0),
                downloadResultLabel.leadingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.leadingAnchor, constant: 14.0),
                downloadResultLabel.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                
                cell.contentView.bottomAnchor.constraint(equalTo: downloadResultLabel.bottomAnchor, constant: 8.0)
            ])
            return cell
        default:
            return UITableViewCell()
        }
    }
}

extension FilesController {
    
    // MARK: Partition settings
    
    func showPartitionControl() {
        let navItem = tabBarController?.navigationItem
        navItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self,
                                                      action: #selector(presentPartitionSettings))
    }
    
    // MARK: addRecentDownload
    
    func addRecentDownload(_ name: String) {
        var recents = (UserDefaults.standard.array(forKey: Self.recentsKey) ?? []) as! [String]
        if !recents.contains(name) {
            recents.append(name)
            UserDefaults.standard.set(recents, forKey: Self.recentsKey)
        }
        tableView.reloadSections(IndexSet([Section.download.rawValue]), with: .none)
    }
}

// MARK: - Targets

extension FilesController {
    
    // MARK: onDownloadInputChanged(_:)
    
    @objc func onDownloadInputChanged(_ sender: UITextField) {
        downloadFilename = sender.text
        let partition = UserDefaults.standard.string(forKey: FilesController.partitionKey)
            ?? FilesController.defaultPartition
        downloadDestination = "/\(partition)/\(downloadFilename ?? "")"
        downloadDestinationLabel?.text = downloadDestination
    }
    
    // MARK: openRecentDownloads()
    
    @objc func openRecentDownloads(_ sender: UIButton) {
        let recents = (UserDefaults.standard.array(forKey: Self.recentsKey) ?? []) as! [String]
        
        let alert = UIAlertController(title: "Recents", message: nil, preferredStyle: .actionSheet)
        let action: (UIAlertAction) -> Void = { [weak self] action in
            guard let self else { return }
            downloadTextField.text = action.title
            onDownloadInputChanged(downloadTextField)
        }
        recents.forEach { name in
            alert.addAction(UIAlertAction(title: name, style: .default, handler: action))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.sourceView = sender
        present(alert, animated: true)
    }
    
    // MARK: onDownloadButtonTapped(_:)
    
    @objc func onDownloadButtonTapped(_ sender: UIButton) {
        downloadTextField.resignFirstResponder()
        guard let downloadFilename, let downloadDestination else { return }
        
        downloadState = .inProgress(percentage: 0, speedInKbps: nil)
        addRecentDownload(downloadFilename)
        let baseController = parent as? BaseViewController
        baseController?.onDeviceStatusReady { [unowned self] in
            _ = fsManager.download(name: downloadDestination, delegate: self)
        }
    }
}

// MARK: - FileDownloadDelegate

extension FilesController: FileDownloadDelegate {
    
    func downloadProgressDidChange(bytesDownloaded: Int, fileSize: Int, timestamp: Date) {
        downloadState = .inProgress(percentage: Float(bytesDownloaded) / Float(fileSize), speedInKbps: nil)
        tableView.reloadSections(IndexSet([Section.download.rawValue]), with: .none)
    }
    
    func downloadDidFail(with error: Error) {
        downloadState = .error(error)
        tableView.reloadSections(IndexSet([Section.download.rawValue]), with: .none)
    }
    
    func downloadDidCancel() {
        downloadState = .cancelled
        tableView.reloadSections(IndexSet([Section.download.rawValue]), with: .none)
    }
    
    func download(of name: String, didFinish data: Data) {
        downloadState = .completed
        tableView.reloadSections(IndexSet([Section.download.rawValue]), with: .none)
    }
}

// MARK: - UITextFieldDelegate

extension FilesController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
