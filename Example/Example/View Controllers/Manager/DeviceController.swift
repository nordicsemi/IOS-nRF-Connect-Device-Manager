/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import iOSMcuManagerLibrary

// MARK: - DeviceController

class DeviceController: UITableViewController, UITextFieldDelegate {
    
    // MARK: Private Properties
    
    private lazy var message: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.text = "Hello!"
        textField.placeholder = "Type your message here"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    private var messageSent: UILabel?
    private lazy var messageSentBackground: UIImageView = {
        let sentBackground = #imageLiteral(resourceName: "bubble_sent")
            .resizableImage(withCapInsets: UIEdgeInsets(top: 17, left: 21, bottom: 17, right: 21),
                            resizingMode: .stretch)
            .withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: sentBackground)
        imageView.tintColor = .nordic
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private var messageReceived: UILabel?
    private lazy var messageReceivedBackground: UIImageView = {
        let receivedBackground = #imageLiteral(resourceName: "bubble_received")
            .resizableImage(withCapInsets: UIEdgeInsets(top: 17, left: 21, bottom: 17, right: 21),
                            resizingMode: .stretch)
            .withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: receivedBackground)
        imageView.tintColor = .zephyr
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private var defaultManager: DefaultManager!
    
    // MARK: UIViewController API
    
    override func viewDidLoad() {
        let baseController = parent as! BaseViewController
        let transport: McuMgrTransport! = baseController.transport
        defaultManager = DefaultManager(transport: transport)
        defaultManager.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let baseController = parent as? BaseViewController
        baseController?.deviceStatusDelegate = self
    }
    
    // MARK: UITableView
    
    enum Section: Int, RawRepresentable, CaseIterable {
        case deviceStatus
        case echo
        
        var title: String {
            switch self {
            case .deviceStatus:
                return "Device Status"
            case .echo:
                return "Echo"
            }
        }
    }
    
    enum EchoSectionRow: Int, RawRepresentable, CaseIterable {
        case input
        case yourMessage
        case responseMessage
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
        case .echo:
            return EchoSectionRow.allCases.count
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
        case .echo:
            return echoSectionCell(for: EchoSectionRow(rawValue: indexPath.row))
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
    
    // MARK: echoSectionCell(for:)
    
    private func echoSectionCell(for row: EchoSectionRow?) -> UITableViewCell {
        switch row {
        case .input:
            let inputCell = UITableViewCell()
            inputCell.selectionStyle = .none
            
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "ic_send"), for: .normal)
            button.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
            button.tintColor = .nordic
            button.translatesAutoresizingMaskIntoConstraints = false
            inputCell.contentView.addSubview(button)
            
            if message.superview != nil {
                message.removeFromSuperview()
            }
            inputCell.contentView.addSubview(message)
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: inputCell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                button.trailingAnchor.constraint(equalTo: inputCell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -8.0),
                button.widthAnchor.constraint(equalToConstant: 40.0),
                button.bottomAnchor.constraint(equalTo: inputCell.contentView.bottomAnchor, constant: -8.0),
                
                message.topAnchor.constraint(equalTo: button.topAnchor),
                message.leadingAnchor.constraint(equalToSystemSpacingAfter: inputCell.contentView.safeAreaLayoutGuide.leadingAnchor, multiplier: 1.0),
                message.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -8.0),
                message.bottomAnchor.constraint(equalTo: button.bottomAnchor)
            ])
            return inputCell
        case .yourMessage:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.size.width, bottom: 0, right: 0)
            
            if let messageSent {
                messageSent.removeFromSuperview()
            }
            
            let label = UILabel(frame: .zero)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .white
            label.textAlignment = .right
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            messageSent = label
            cell.contentView.addSubview(label)
            
            messageSentBackground.removeFromSuperview()
            cell.contentView.addSubview(messageSentBackground)
            cell.contentView.sendSubviewToBack(messageSentBackground)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                label.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: cell.contentView.safeAreaLayoutGuide.leadingAnchor, multiplier: 2.0),
                label.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -32.0),
                
                messageSentBackground.topAnchor.constraint(equalTo: label.topAnchor),
                messageSentBackground.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -7.0),
                messageSentBackground.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 14.0),
                messageSentBackground.bottomAnchor.constraint(equalTo: label.bottomAnchor),
                
                cell.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: messageSentBackground.bottomAnchor, multiplier: 1.0)
            ])
            return cell
        case .responseMessage:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.size.width, bottom: 0, right: 0)
            
            if let messageReceived {
                messageReceived.removeFromSuperview()
            }
            
            // There's a warning to not pin the trailing anchor of a UILabel directly to its superview.
            // It did not fix the issues we were trying to solve, but it did remove the warning.
            let rightSideMarker = UIView()
            rightSideMarker.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(rightSideMarker)
            
            let label = UILabel(frame: .zero)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .white
            label.textAlignment = .natural
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            
            messageReceived = label
            cell.contentView.addSubview(label)
            
            messageReceivedBackground.removeFromSuperview()
            cell.contentView.addSubview(messageReceivedBackground)
            cell.contentView.sendSubviewToBack(messageReceivedBackground)
            
            NSLayoutConstraint.activate([
                rightSideMarker.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor),
                rightSideMarker.trailingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor),
                rightSideMarker.widthAnchor.constraint(equalToConstant: 12.0),
                rightSideMarker.heightAnchor.constraint(equalToConstant: 20.0),
                
                label.topAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.topAnchor, constant: 8.0),
                label.leadingAnchor.constraint(equalTo: cell.contentView.safeAreaLayoutGuide.leadingAnchor, constant: 24.0),
                label.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
                
                messageReceivedBackground.topAnchor.constraint(equalTo: label.topAnchor),
                messageReceivedBackground.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -14.0),
                messageReceivedBackground.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 7.0),
                messageReceivedBackground.bottomAnchor.constraint(equalTo: label.bottomAnchor),
                
                cell.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: messageReceivedBackground.bottomAnchor, multiplier: 1.5)
            ])
            return cell
        case .none:
            return UITableViewCell()
        }
    }
    
    // MARK: textFieldShouldReturn(_:)
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        sendTapped(sender)
        return true
    }
    
    // MARK: sendTapped(_:)
    
    @objc func sendTapped(_ sender: UIResponder) {
        sender.resignFirstResponder()
        guard let baseViewController = parent as? BaseViewController else { return }
        let text = message.text ?? ""
        baseViewController.onDeviceStatusReady { [unowned self] in
            send(message: text)
        }
    }
    
    // MARK: send
    
    private func send(message: String) {
        messageSent?.text = message
        messageSent?.isHidden = false
        messageSentBackground.isHidden = false
        messageReceived?.isHidden = true
        messageReceivedBackground.isHidden = true
        
        defaultManager.echo(message, callback: sendCallback)
    }
    
    private lazy var sendCallback: McuMgrCallback<McuMgrEchoResponse> = { [weak self] (response: McuMgrEchoResponse?, error: Error?) in
        
        if let response, let messageReceived = self?.messageReceived {
            self?.messageReceived?.text = response.response
            // Do not ask. I do not know wtf this only works if we make this call.
            // Theoretically, with AutoLayout enabled, the Label canot size itself and instead
            // it sizes itself based on its constraints. I don't know... I found this fix by
            // accident.
            self?.messageReceived?.sizeToFit()
        }
        
        if let error {
            if case let McuMgrTransportError.insufficientMtu(newMtu) = error {
                // Change MTU to the recommended new value.
                do {
                    try self?.defaultManager.setMtu(newMtu)
                    // MTU Set successful and we have the text, so try again.
                    if let messageText = self?.messageSent?.text {
                        self?.send(message: messageText)
                    }
                } catch McuManagerError.mtuValueHasNotChanged {
                    // If MTU value did not change, try reassembly.
                    if let messageText = self?.messageSent?.text,
                       let bleTransport = self?.defaultManager.transport as? McuMgrBleTransport,
                       !bleTransport.chunkSendDataToMtuSize {
                        bleTransport.chunkSendDataToMtuSize = true
                        self?.send(message: messageText)
                    }
                } catch let setMtuError {
                    self?.onError(setMtuError)
                }
            }
            self?.onError(error)
            return
        }
        
        self?.messageReceived?.isHidden = false
        self?.messageReceivedBackground.isHidden = false
    }
    
    // MARK: onError
    
    private func onError(_ error: some Error) {
        messageReceived?.text = error.localizedDescription
        messageReceived?.sizeToFit()
        messageReceived?.isHidden = false
        messageReceivedBackground.tintColor = .systemRed
        messageReceivedBackground.isHidden = false
    }
}

// MARK: - DeviceStatusdelegate

extension DeviceController: DeviceStatusManager.Delegate {
    
    func statusInfoDidChange(_ info: DeviceStatusInfo) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
    
    func transportStateDidChange(_ state: PeripheralState) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
    
    func otaStatusChanged(_ status: OTAStatus) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
    
    func observabilityStatusChanged(_ statusInfo: ObservabilityStatusInfo) {
        tableView.reloadSections(IndexSet([Section.deviceStatus.rawValue]), with: .none)
    }
}
