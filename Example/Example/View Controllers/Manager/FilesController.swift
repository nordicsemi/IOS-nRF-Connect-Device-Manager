/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import iOSMcuManagerLibrary
import UniformTypeIdentifiers

// MARK: - FilesController

final class FilesController: UITableViewController {
    
    internal static let partitionKey = "partition"
    internal static let recentsKey = "recents"
    
    /**
     Source: [LittleFS GitHub Project](https://github.com/ARMmbed/littlefs)
     */
    internal static let defaultPartition = "lfs1"
    
    // MARK: Logic Properties
    
    internal enum FsManagerOpState {
        case selectFile
        case ready
        case inProgress(percentage: Float, speedInKbps: Double?)
        case paused
        case cancelled
        case error(_ error: Error)
        case completed
    }
    
    internal var uploadFilename: String?
    internal var uploadDestination: String?
    internal var uploadData: Data?
    internal var uploadBytesSent: Int!
    internal var uploadTimestamp: Date!
    internal var uploadState: FsManagerOpState = .selectFile
    
    internal var downloadFilename: String?
    internal var downloadDestination: String?
    internal var downloadedFileURL: URL?
    internal var downloadState: FsManagerOpState = .selectFile
    
    internal var fsManager: FileSystemManager!
    
    // MARK: UI Properties
    
    internal weak var uploadStatus: UILabel?
    internal var uploadProgress: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progress = 0.0
        progressView.tintColor = .nordic
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    internal lazy var uploadButton: UIButton = {
        let button = UIButton()
        button.setTitle("Start", for: .normal)
        button.setTitleColor(.nordic, for: .normal)
        button.setTitleColor(.secondary, for: .disabled)
        button.addTarget(self, action: #selector(onUploadButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    internal lazy var uploadCancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(onUploadCancelButtonTapped), for: .touchUpInside)
        if #available(iOS 14.0, *) {
            button.role = .destructive
        }
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    internal lazy var downloadTextField: UITextField = {
        let textField = UITextField()
        textField.addTarget(self, action: #selector(onDownloadInputChanged), for: .valueChanged)
        textField.addTarget(self, action: #selector(onDownloadInputChanged), for: .editingChanged)
        textField.placeholder = "Type file name here."
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.delegate = self
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    internal lazy var downloadRecentsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "ic_recents"), for: .normal)
        button.addTarget(self, action: #selector(openRecentDownloads), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .secondary
        button.isEnabled = false
        return button
    }()
    
    internal lazy var downloadActionButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "ic_download"), for: .normal)
        button.addTarget(self, action: #selector(onDownloadButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    internal var downloadProgress: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progress = 0.0
        progressView.tintColor = .nordic
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    internal weak var downloadDestinationLabel: UILabel?
    internal var downloadResultLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    internal lazy var downloadPreviewButton: UIButton = {
        let button = UIButton()
        button.setTitle("Preview", for: .normal)
        button.setTitleColor(.nordic, for: .normal)
        button.setTitleColor(.secondary, for: .disabled)
        button.addTarget(self, action: #selector(onPreviewButtonTapped), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    internal lazy var downloadExportButton: UIButton = {
        let button = UIButton()
        button.setTitle("Export", for: .normal)
        button.setTitleColor(.nordic, for: .normal)
        button.setTitleColor(.secondary, for: .disabled)
        button.addTarget(self, action: #selector(onExportButtonTapped), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: UIViewController API
    
    override func viewDidAppear(_ animated: Bool) {
        showPartitionControl()
        
        let baseController = parent as? BaseViewController
        baseController?.deviceStatusDelegate = self
        
        let transport: McuMgrTransport! = baseController?.transport
        fsManager = FileSystemManager(transport: transport)
        fsManager.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController?.navigationItem.rightBarButtonItem = nil
    }
    
    // MARK: UITableView
    
    enum Section: Int, RawRepresentable, CaseIterable {
        case deviceStatus
        case upload
        case download
        
        var title: String {
            switch self {
            case .deviceStatus:
                return "Device Status"
            case .upload:
                return "Upload"
            case .download:
                return "Download"
            }
        }
    }
    
    enum UploadSectionRow: Int, RawRepresentable, CaseIterable {
        case selectFile
        case fileSize
        case fileDestination
        case uploadState
        case uploadStart
    }
    
    enum DownloadSectionRow: Int, RawRepresentable, CaseIterable {
        case downloadInput
        case downloadPath
        case downloadOutput
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        return section.title
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .deviceStatus:
            return DeviceStatusRow.allCases.count
        case .upload:
            return UploadSectionRow.allCases.count
        case .download:
            return DownloadSectionRow.allCases.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)
        switch section {
        case .deviceStatus:
            return (parent as? BaseViewController)?.tableView(tableView, cellForRowAt: indexPath)
                ?? UITableViewCell()
        case .upload:
            return uploadSectionCell(for: UploadSectionRow(rawValue: indexPath.row))
        case .download:
            return downloadSectionCell(for: DownloadSectionRow(rawValue: indexPath.row))
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)
        switch section {
        case .deviceStatus:
            (parent as? BaseViewController)?.onDeviceStatusAccessoryTapped(at: indexPath)
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - DeviceStatusDelegate

extension FilesController: DeviceStatusManager.Delegate {
    
    func transportStateDidChange(_ state: PeripheralState) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
    
    func statusInfoDidChange(_ info: DeviceStatusInfo) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
    
    func otaStatusChanged(_ status: OTAStatus) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
    
    func observabilityStatusChanged(_ statusInfo: ObservabilityStatusInfo) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
}
