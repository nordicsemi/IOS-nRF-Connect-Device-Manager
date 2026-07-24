//
//  FilesController+Upload.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 04/06/2026.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import iOSMcuManagerLibrary

extension FilesController {
    
    // MARK: uploadSectionCell(for:)
    
    func uploadSectionCell(for row: UploadSectionRow?) -> UITableViewCell {
        switch row {
        case .selectFile:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "selectFile")
            cell.selectionStyle = .none
            
            let filenameLabel = UILabel()
            filenameLabel.lineBreakMode = .byTruncatingTail
            filenameLabel.text = uploadFilename ?? "No file selected"
            filenameLabel.textColor = uploadFilename != nil ? .primary : .secondary
            filenameLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(filenameLabel)
            
            let selectFileButton = UIButton()
            selectFileButton.setTitle("Select File", for: .normal)
            selectFileButton.setTitleColor(.nordic, for: .normal)
            selectFileButton.setTitleColor(.secondary, for: .disabled)
            selectFileButton.addTarget(self, action: #selector(selectFile), for: .touchUpInside)
            selectFileButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            selectFileButton.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(selectFileButton)
            
            NSLayoutConstraint.activate([
                selectFileButton.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                selectFileButton.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: filenameLabel.trailingAnchor, multiplier: 1.0),
                selectFileButton.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                
                filenameLabel.firstBaselineAnchor.constraint(equalTo: selectFileButton.firstBaselineAnchor),
                filenameLabel.leadingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.leadingAnchor, constant: 14.0),
                
                cell.contentView.bottomAnchor.constraint(equalTo: selectFileButton.bottomAnchor, constant: 8.0)
            ])
            
            return cell
        case .fileSize, .fileDestination, .uploadState:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "fileData")
            cell.selectionStyle = .none
            cell.textLabel?.textColor = .secondary
            cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
            switch row {
            case .fileSize:
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = .useAll
                formatter.countStyle = .file
                formatter.includesUnit = true
                formatter.isAdaptive = true
                if let uploadData {
                    cell.textLabel?.text = "Size: \(formatter.string(fromByteCount: Int64(uploadData.bytes.byteCount)))"
                } else {
                    cell.textLabel?.text = "Size: N/A"
                }
            case .fileDestination:
                cell.textLabel?.text = "Destination: \(uploadDestination ?? "N/A")"
            case .uploadState:
                uploadStatus = cell.textLabel
                
                switch uploadState {
                case .selectFile:
                    cell.textLabel?.text = "State: N/A"
                    cell.textLabel?.textColor = .secondary
                case .ready:
                    cell.textLabel?.text = "State: READY"
                    cell.textLabel?.textColor = .secondary
                case .inProgress(_ , let speed):
                    if let speed {
                        cell.textLabel?.text = "State: UPLOADING... (\(String(format: "%.2f", speed)) kB/s)"
                    } else {
                        cell.textLabel?.text = "State: UPLOADING..."
                    }
                    cell.textLabel?.textColor = .primary
                case .paused:
                    cell.textLabel?.text = "State: PAUSED"
                    cell.textLabel?.textColor = .secondary
                case .cancelled:
                    cell.textLabel?.text = "State: CANCELLED"
                    cell.textLabel?.textColor = .red
                case .error(let error):
                    cell.textLabel?.text = "State: \(error.localizedDescription)"
                    cell.textLabel?.textColor = .red
                case .completed:
                    cell.textLabel?.text = "State: UPLOAD COMPLETE"
                    cell.textLabel?.textColor = .secondary
                }
            default:
                break
            }
            return cell
        case .uploadStart:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "uploadButtons")
            cell.selectionStyle = .none
            if uploadProgress.superview != nil {
                uploadProgress.removeFromSuperview()
            }
            if uploadButton.superview != nil {
                uploadButton.removeFromSuperview()
            }
            if uploadCancelButton.superview != nil {
                uploadCancelButton.removeFromSuperview()
            }
            cell.contentView.addSubview(uploadProgress)
            cell.contentView.addSubview(uploadButton)
            cell.contentView.addSubview(uploadCancelButton)
            
            switch uploadState {
            case .selectFile:
                uploadProgress.setProgress(0.0, animated: false)
                uploadButton.setTitle("Start", for: .normal)
                uploadButton.isEnabled = false
            case .ready:
                uploadProgress.setProgress(0.0, animated: false)
                uploadButton.setTitle("Start", for: .normal)
                uploadButton.isEnabled = true
            case .inProgress(let progress, _):
                uploadProgress.setProgress(progress, animated: true)
                uploadButton.setTitle("Pause", for: .normal)
            case .cancelled:
                uploadProgress.setProgress(0.0, animated: true)
                uploadButton.isEnabled = false
            case .paused:
                uploadButton.setTitle("Resume", for: .normal)
            case .error:
                uploadProgress.setProgress(0.0, animated: true)
                uploadButton.setTitle("Start", for: .normal)
                uploadButton.isEnabled = false
            case .completed:
                uploadProgress.setProgress(0.0, animated: true)
                uploadButton.setTitle("Start", for: .normal)
                uploadButton.isEnabled = false
            }
            
            NSLayoutConstraint.activate([
                uploadProgress.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                uploadProgress.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                uploadProgress.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                
                uploadButton.topAnchor.constraint(equalTo: uploadProgress.bottomAnchor, constant: 8.0),
                uploadButton.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                
                uploadCancelButton.topAnchor.constraint(equalTo: uploadButton.topAnchor),
                uploadCancelButton.trailingAnchor.constraint(equalTo: uploadButton.leadingAnchor, constant: 8.0),
                
                cell.contentView.bottomAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 8.0)
            ])
            return cell
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - Targets

extension FilesController {
    
    // MARK: presentPartitionSettings()
    
    @objc func presentPartitionSettings() {
        let alert = UIAlertController(title: "Settings",
                                      message: "Specify the mount point,\ne.g. \"lfs1\" or \"nffs\":",
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Partition"
            field.autocorrectionType = .no
            field.autocapitalizationType = .none
            field.returnKeyType = .done
            field.clearButtonMode = .always
            field.text = UserDefaults.standard
                .string(forKey: FilesController.partitionKey)
                ?? FilesController.defaultPartition
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let newName = alert.textFields![0].text
            if let newName = newName, !newName.isEmpty {
                UserDefaults.standard.set(alert.textFields![0].text,
                                          forKey: FilesController.partitionKey)
                self.tableView.reloadData()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Default (\(FilesController.defaultPartition))",
                                      style: .default) { _ in
            UserDefaults.standard.set(FilesController.defaultPartition,
                                      forKey: FilesController.partitionKey)
            self.tableView.reloadData()
        })
        present(alert, animated: true)
    }
    
    // MARK: selectFile(_:)
    
    @objc func selectFile(_ sender: UIButton) {
        let supportedDocumentTypes = ["public.data", "public.content"]
        let importMenu = UIDocumentPickerViewController(documentTypes: supportedDocumentTypes, in: .import)
        importMenu.allowsMultipleSelection = false
        importMenu.delegate = self
        importMenu.popoverPresentationController?.sourceView = sender
        present(importMenu, animated: true, completion: nil)
    }
    
    // MARK: onUploadButtonTapped(_:)
    
    @objc func onUploadButtonTapped(_ sender: UIButton) {
        switch uploadState {
        case .ready:
            guard let uploadFilename, let uploadDestination, let uploadData else { return }
            
            addRecentDownload(uploadFilename)
            uploadState = .inProgress(percentage: 0.0, speedInKbps: nil)
            tableView.reloadSections(IndexSet([Section.upload.rawValue]), with: .none)

            let baseController = parent as? BaseViewController
            baseController?.onDeviceStatusReady { [unowned self] in
                _ = fsManager.upload(name: uploadDestination, data: uploadData, delegate: self)
                tableView.reloadSections(IndexSet([Section.upload.rawValue]), with: .none)
            }
        case .inProgress:
            fsManager.pauseTransfer()
        case .paused:
            // on Resume
            fsManager.continueTransfer()
        case .selectFile, .cancelled, .completed, .error:
            break
        }
    }
    
    // MARK: onUploadCancelButtonTapped(_:)
    
    @objc func onUploadCancelButtonTapped(_ sender: UIButton) {
        fsManager.cancelTransfer()
    }
}

// MARK: - UIDocumentPickerDelegate

extension FilesController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentAt url: URL) {
        defer {
            tableView.reloadSections(IndexSet([Section.upload.rawValue]), with: .none)
        }
        guard let data = dataFrom(url: url) else {
            uploadButton.isEnabled = false
            return
        }
        uploadData = data
        uploadFilename = url.lastPathComponent
        uploadTimestamp = nil

        let partition: String = UserDefaults.standard.string(forKey: FilesController.partitionKey)
            ?? FilesController.defaultPartition
        uploadDestination = "/\(partition)/\(url.lastPathComponent)"
        
        uploadButton.isEnabled = true
        uploadState = .ready
    }
    
    private func dataFrom(url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            uploadStatus?.textColor = .systemRed
            uploadStatus?.text = error.localizedDescription
            return nil
        }
    }
}

// MARK: - FileUploadDelegate

extension FilesController: FileUploadDelegate {
    
    func uploadProgressDidChange(bytesSent: Int, fileSize: Int, timestamp: Date) {
        if uploadTimestamp == nil {
            uploadTimestamp = timestamp
            uploadBytesSent = bytesSent
        }
        
        switch uploadState {
        case .ready, .inProgress:
            // Date.timeIntervalSince1970 returns seconds
            let msSinceUploadBegan = max((timestamp.timeIntervalSince1970 - uploadTimestamp.timeIntervalSince1970) * 1000, 1)
            let speedInKiloBytesPerSecond: Double
            if bytesSent < fileSize {
                let bytesSentSinceUploadBegan = bytesSent - uploadBytesSent
                // bytes / ms = kB/s
                speedInKiloBytesPerSecond = Double(bytesSentSinceUploadBegan) / msSinceUploadBegan
            } else {
                // bytes / ms = kB/s
                speedInKiloBytesPerSecond = Double(fileSize - uploadBytesSent) / msSinceUploadBegan
            }
            uploadState = .inProgress(percentage: Float(bytesSent) / Float(fileSize),
                                      speedInKbps: speedInKiloBytesPerSecond)
            
            tableView.reloadSections(IndexSet([Section.upload.rawValue]), with: .none)
        default:
            break // Ignore
        }
    }
    
    func uploadDidFail(with error: Error) {
        uploadProgress.setProgress(0, animated: true)
        uploadState = .error(error)
        tableView.reloadSections(IndexSet([Section.upload.rawValue]), with: .none)
    }
    
    func uploadDidCancel() {
        uploadProgress.setProgress(0, animated: true)
        uploadState = .cancelled
        tableView.reloadSections(IndexSet([Section.upload.rawValue]), with: .none)
    }
    
    func uploadDidFinish() {
        if let uploadFilename {
            addRecentDownload(uploadFilename)
        }
        uploadTimestamp = nil
        uploadData = nil
        uploadProgress.setProgress(0, animated: true)
        uploadState = .completed
        tableView.reloadSections(IndexSet([Section.upload.rawValue]), with: .none)
    }
}
