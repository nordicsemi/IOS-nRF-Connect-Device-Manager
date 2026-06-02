/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import iOSMcuManagerLibrary

// MARK: - DiagnosticsController

final class DiagnosticsController: UITableViewController {
    
    // MARK: Private Properties
    
    private var observabilityStatusInfo: ObservabilityStatusInfo?
    
    private lazy var observabilitySectionStatusLabel: UILabel = {
        let statusLabel = UILabel()
        statusLabel.text = "Status: Offline"
        statusLabel.textColor = .secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        return statusLabel
    }()
    private lazy var observabilitySectionStatusActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var observabilitySectionStatusPendingLabel: UILabel?
    private var observabilitySectionStatusUploadedLabel: UILabel?
    private lazy var observabilityButton: UIButton = {
        let button = UIButton()
        button.setTitle("Connect", for: .normal)
        button.setTitleColor(.nordic, for: .normal)
        button.addTarget(self, action: #selector(observabilityTapped), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var statsLabel: UILabel = {
        let statusLabel = UILabel()
        statusLabel.text = "Tap Refresh to download stats"
        statusLabel.textColor = .secondary
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        return statusLabel
    }()
    
    // MARK: @objc
    
    @objc func refreshTapped(_ sender: UIResponder) {
        guard let baseViewController = parent as? BaseViewController else { return }
        baseViewController.onDeviceStatusReady { [unowned self] in
            requestStats()
        }
    }
    
    @objc func observabilityTapped(_ sender: UIResponder) {
        guard let baseViewController = parent as? BaseViewController else { return }
        baseViewController.observabilityButtonTapped()
    }
    
    @objc func observabilityLearnMoreTapped(_ sender: UIResponder) {
        guard let baseViewController = parent as? BaseViewController else { return }
        let alertController = UIAlertController(title: "Help", message: nil, preferredStyle: .alert)
        alertController.message = """
        
        nRF Cloud Observability is a comprehensive suite of monitoring, diagnostics, and actionable insights for embedded devices. It allows developers and engineering teams to track, analyze, and act on device behavior and reliability in real time.
            
        nRF Connect Device Manager forwards Chunks payload obtained from embedded devices with Monitoring & Diagnostics Service (MDS) to nRF Cloud Services for analysis.
        """
        if let url = URL(string: "https://docs.nordicsemi.com/bundle/nrf-cloud/page/index.html/") {
            alertController.addAction(UIAlertAction(title: "Discover nRF Cloud", style: .default, handler: { _ in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
        }
        baseViewController.present(alertController, addingCancelAction: true,
                                   cancelActionTitle: "OK")
    }
    
    // MARK: Private Properties
    
    private var statsManager: StatsManager!
    
    // MARK: UIViewController
    
    override func viewDidAppear(_ animated: Bool) {
        guard let baseController = parent as? BaseViewController else { return }
        baseController.deviceStatusDelegate = self
        
        let transport: McuMgrTransport! = baseController.transport
        statsManager = StatsManager(transport: transport)
        statsManager.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
    }
    
    // MARK: UITableView
    
    enum Section: Int, RawRepresentable, CaseIterable {
        case deviceStatus
        case observability
        case stats
        
        var title: String {
            switch self {
            case .deviceStatus:
                return "Device Status"
            case .observability:
                return "Observability"
            case .stats:
                return "Stats"
            }
        }
    }
    
    enum ObservabilitySectionRow: Int, RawRepresentable, CaseIterable {
        case status
        case pendingBytes
        case uploadedBytes
        case learnMoreUpdate
    }
    
    enum StatsSectionRow: Int, RawRepresentable, CaseIterable {
        case stats
        case refreshButton
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
        case .observability:
            return ObservabilitySectionRow.allCases.count
        case .stats:
            return StatsSectionRow.allCases.count
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
        case .observability:
            return observabilitySectionCell(for: ObservabilitySectionRow(rawValue: indexPath.row))
        case .stats:
            return statsSectionCell(for: StatsSectionRow(rawValue: indexPath.row))
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
    
    // MARK: observabilitySectionCell(for:)
    
    private func observabilitySectionCell(for row: ObservabilitySectionRow?) -> UITableViewCell {
        switch row {
        case .status:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "status")
            cell.selectionStyle = .none
            if observabilitySectionStatusLabel.superview != nil {
                observabilitySectionStatusLabel.removeFromSuperview()
            }
            if observabilitySectionStatusActivityIndicator.superview != nil {
                observabilitySectionStatusActivityIndicator.removeFromSuperview()
            }
            cell.contentView.addSubview(observabilitySectionStatusLabel)
            cell.contentView.addSubview(observabilitySectionStatusActivityIndicator)
            
            NSLayoutConstraint.activate([
                observabilitySectionStatusActivityIndicator.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                observabilitySectionStatusActivityIndicator.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -12.0),
                observabilitySectionStatusActivityIndicator.widthAnchor.constraint(equalToConstant: 30.0),
                observabilitySectionStatusActivityIndicator.heightAnchor.constraint(equalToConstant: 30.0),
                
                observabilitySectionStatusLabel.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 12.0),
                observabilitySectionStatusLabel.leadingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
                observabilitySectionStatusLabel.trailingAnchor.constraint(equalTo: observabilitySectionStatusActivityIndicator.leadingAnchor),
                
                cell.contentView.bottomAnchor.constraint(equalTo: observabilitySectionStatusLabel.bottomAnchor, constant: 12.0)
            ])
            return cell
        case .pendingBytes:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "bytes")
            cell.selectionStyle = .none
            if let observabilityStatusInfo {
                cell.textLabel?.text = observabilityStatusInfo.pendingBytesString()
            } else {
                cell.textLabel?.text = "Pending: 0 bytes"
            }
            cell.textLabel?.textColor = .secondary
            observabilitySectionStatusPendingLabel = cell.textLabel
            return cell
        case .uploadedBytes:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "bytes")
            cell.selectionStyle = .none
            if let observabilityStatusInfo {
                cell.textLabel?.text = observabilityStatusInfo.uploadedBytesString()
            } else {
                cell.textLabel?.text = "Uploaded: 0 bytes"
            }
            cell.textLabel?.textColor = .secondary
            observabilitySectionStatusUploadedLabel = cell.textLabel
            return cell
        case .learnMoreUpdate:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "learnMore")
            cell.selectionStyle = .none
            
            cell.textLabel?.text = "Learn More"
            cell.textLabel?.textColor = .nordic
            cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
            let learnMoreTapGesture = UITapGestureRecognizer(target: self, action: #selector(observabilityLearnMoreTapped(_:)))
            cell.textLabel?.isUserInteractionEnabled = true
            cell.textLabel?.addGestureRecognizer(learnMoreTapGesture)
            
            if observabilityButton.superview != nil {
                observabilityButton.removeFromSuperview()
            }
            cell.contentView.addSubview(observabilityButton)
            
            NSLayoutConstraint.activate([
                observabilityButton.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                observabilityButton.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0)
            ])
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: statsSectionCell(for:)
    
    private func statsSectionCell(for row: StatsSectionRow?) -> UITableViewCell {
        switch row {
        case .stats:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "stats")
            cell.selectionStyle = .none
            cell.textLabel?.numberOfLines = 0
            
            if statsLabel.superview != nil {
                statsLabel.removeFromSuperview()
            }
            
            cell.contentView.addSubview(statsLabel)
            NSLayoutConstraint.activate([
                statsLabel.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                statsLabel.leadingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.leadingAnchor, constant: 14.0),
                statsLabel.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                statsLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8.0)
            ])
            return cell
        case .refreshButton:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "statsRefresh")
            cell.selectionStyle = .none
            
            let refreshButton = UIButton()
            refreshButton.setTitle("Refresh", for: .normal)
            refreshButton.setTitleColor(.nordic, for: .normal)
            refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
            refreshButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            refreshButton.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(refreshButton)
            
            NSLayoutConstraint.activate([
                refreshButton.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                refreshButton.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -14.0),
                
                cell.contentView.bottomAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 8.0)
            ])
            return cell
        case .none:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - Private

private extension DiagnosticsController {
 
    // MARK: requestStats
    
    func requestStats() {
        Task { @MainActor in
            do {
                let response = try await statsManager.list()
                statsLabel.text = ""
                statsLabel.textColor = .primary
                
                guard let modules = response.names, !modules.isEmpty else {
                    statsLabel.text = "No stats found"
                    return
                }
                
                var output: String = ""
                for module in modules {
                    do {
                        let moduleStats = try await statsManager.read(module: module)
                        output += moduleStatsString(module, stats: moduleStats, error: nil)
                    } catch let statsError {
                        output += moduleStatsString(module, stats: nil, error: statsError)
                    }
                }
                
                statsLabel.text = output
                tableView.reloadSections(IndexSet([Section.stats.rawValue]), with: .none)
            } catch {
                statsLabel.textColor = .systemRed
                statsLabel.text = error.localizedDescription
                tableView.reloadSections(IndexSet([Section.stats.rawValue]), with: .none)
            }
        }
    }
    
    // MARK: moduleStatsString(_:stats:error:)
    
    nonisolated
    func moduleStatsString(_ module: String, stats: McuMgrStatsResponse?, error: (any Error)?) -> String {
        var resultString = "\(module)"
        if let stats {
            if let group = stats.group {
                resultString += " (\(group))"
            }
            resultString += ":\n"
            if let fields = stats.fields {
                for field in fields {
                    resultString += "• \(field.key): \(field.value)\n"
                }
            } else {
                resultString += "• Empty\n"
            }
        } else {
            resultString += "\(error?.localizedDescription ?? "Unknown Error")\n"
        }
        
        resultString += "\n"
        return resultString
    }
    
    // MARK: showObservabilityActivityIndicator(_:)
    
    func showObservabilityActivityIndicator(_ isVisible: Bool) {
        observabilitySectionStatusActivityIndicator.hidesWhenStopped = true
        if isVisible {
            observabilitySectionStatusActivityIndicator.isHidden = false
            if !observabilitySectionStatusActivityIndicator.isAnimating {
                observabilitySectionStatusActivityIndicator.startAnimating()
            }
        } else {
            observabilitySectionStatusActivityIndicator.stopAnimating()
        }
    }
}

// MARK: - DeviceStatusDelegate

extension DiagnosticsController: DeviceStatusManager.Delegate {
    
    func connectionStateDidChange(_ state: PeripheralState) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
        // Reload in separate command, otherwise we get a 'blinking' header effect.
        tableView.reloadSections(IndexSet([Section.observability.rawValue]), with: .none)
    }
    
    func statusInfoDidChange(_ info: DeviceStatusInfo) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
        tableView.reloadSections(IndexSet([Section.observability.rawValue]), with: .none)
    }
    
    func otaStatusChanged(_ status: OTAStatus) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
        tableView.reloadSections(IndexSet([Section.observability.rawValue]), with: .none)
    }
    
    func observabilityStatusChanged(_ statusInfo: ObservabilityStatusInfo) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
        
        switch statusInfo.status {
        case .receivedEvent(let event):
            switch event {
            case .connected:
                observabilitySectionStatusLabel.text = "Status: Connected over BLE"
                observabilitySectionStatusLabel.textColor = .systemYellow
                observabilityButton.setTitle("Disconnect", for: .normal)
                showObservabilityActivityIndicator(false)
            case .disconnected:
                observabilitySectionStatusLabel.text = "Status: Offline"
                observabilitySectionStatusLabel.textColor = .secondaryLabel
                observabilityButton.setTitle("Connect", for: .normal)
                showObservabilityActivityIndicator(false)
            case .notifications:
                observabilitySectionStatusLabel.text = "Status: Notifications Enabled"
                observabilitySectionStatusLabel.textColor = .systemYellow
                break
            case .authenticated:
                observabilitySectionStatusLabel.text = "Status: Authenticated"
                observabilitySectionStatusLabel.textColor = .systemYellow
            case .unauthorized:
                observabilitySectionStatusLabel.text = "Status: Unauthorized"
                observabilitySectionStatusLabel.textColor = .systemYellow
                observabilityButton.setTitle("Disconnect", for: .normal)
                showObservabilityActivityIndicator(false)
            case .online(let isTrue):
                if isTrue {
                    observabilitySectionStatusLabel.text = "Status: Online"
                    observabilitySectionStatusLabel.textColor = .systemGreen
                } else {
                    observabilitySectionStatusLabel.text = "Status: Network Unavailable"
                    observabilitySectionStatusLabel.textColor = .systemYellow
                    observabilityButton.setTitle("Retry Network", for: .normal)
                }
                showObservabilityActivityIndicator(true)
            case .updatedChunk(let chunk):
                switch chunk.status {
                case .pendingUpload:
                    observabilitySectionStatusLabel.text = "Status: Pending Upload"
                    observabilitySectionStatusLabel.textColor = .systemYellow
                    break
                case .uploading:
                    observabilitySectionStatusLabel.text = "Status: Uploading"
                    observabilityButton.setTitle("Disconnect", for: .normal)
                case .success:
                    observabilitySectionStatusLabel.text = "Status: Awaiting New Chunks"
                    observabilitySectionStatusLabel.textColor = .systemGreen
                    observabilityButton.setTitle("Disconnect", for: .normal)
                case .uploadError:
                    // Should be handled by .errorEvent
                    break
                }
                
                showObservabilityActivityIndicator(true)
                observabilityStatusInfo = statusInfo
                observabilitySectionStatusPendingLabel?.text = statusInfo.pendingBytesString()
                observabilitySectionStatusUploadedLabel?.text = statusInfo.uploadedBytesString()
            }
        case .connectionClosed:
            showObservabilityActivityIndicator(false)
            
            observabilitySectionStatusLabel.text = "Status: Offline"
            observabilitySectionStatusLabel.textColor = .secondaryLabel
            observabilityButton.setTitle("Connect", for: .normal)
        case .unsupported:
            showObservabilityActivityIndicator(false)
            
            observabilitySectionStatusLabel.text = "Status: Unsupported"
            observabilitySectionStatusLabel.textColor = .secondaryLabel
            observabilityButton.setTitle("Connect", for: .normal)
        case .errorEvent(let error):
            showObservabilityActivityIndicator(false)
            
            observabilitySectionStatusLabel.text = "Status: \(error.localizedDescription)"
            observabilitySectionStatusLabel.textColor = .systemRed
            observabilityButton.setTitle("Reconnect", for: .normal)
        case .pairingError:
            observabilitySectionStatusLabel.text = "Status: Pairing Error"
            observabilitySectionStatusLabel.textColor = .systemRed
            observabilityButton.setTitle("Reconnect", for: .normal)
        }
    }
}
