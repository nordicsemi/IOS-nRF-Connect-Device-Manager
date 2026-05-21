/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit

// MARK: - IntroViewController

final class IntroViewController: UITableViewController {

    enum Section: Int, RawRepresentable, CaseIterable {
        case header
        case body
        case links
        case continueButton
    }
    
    // MARK: Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .header:
            return 2
        case .body:
            return 1
        case .links:
            return 3
        case .continueButton:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case IndexPath(row: 0, section: Section.header.rawValue):
            return 180
        default:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.textColor = .primary
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.numberOfLines = 1
        cell.textLabel?.textAlignment = .natural
        cell.imageView?.image = nil
        cell.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0) // System default.
        cell.accessoryType = .none
        
        switch indexPath {
        case IndexPath(row: 0, section: Section.header.rawValue):
            let imageView = UIImageView(image: UIImage(named: "device_manager"))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .right
            cell.contentView.addSubview(imageView)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalToSystemSpacingBelow: cell.contentView.topAnchor, multiplier: 1.0),
                imageView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor)
            ])
        case IndexPath(row: 1, section: Section.header.rawValue):
            cell.textLabel?.text = "Welcome"
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
            cell.textLabel?.textAlignment = .center
        case IndexPath(row: 0, section: Section.body.rawValue):
            cell.textLabel?.text = """
            nRF Connect Device Manager is a generic tool for updating and managing devices over Bluetooth LE.
            
            A device running nRF Connect SDK, Zephyr or Mynewt firmware with support for MCU management subsystem is required.
            """
            cell.textLabel?.numberOfLines = 0
        case IndexPath(row: 0, section: Section.links.rawValue):
            cell.textLabel?.text = "nRF Connect SDK"
            cell.textLabel?.textColor = .nordic
            cell.textLabel?.numberOfLines = 1
            cell.accessoryType = .disclosureIndicator
        case IndexPath(row: 1, section: Section.links.rawValue):
            cell.textLabel?.text = "SMP Server Sample"
            cell.textLabel?.textColor = .nordic
            cell.textLabel?.numberOfLines = 1
            cell.accessoryType = .disclosureIndicator
        case IndexPath(row: 2, section: Section.links.rawValue):
            cell.textLabel?.text = "Source Code (GitHub)"
            cell.textLabel?.textColor = .nordic
            cell.textLabel?.numberOfLines = 1
            cell.accessoryType = .disclosureIndicator
        case IndexPath(row: 0, section: Section.continueButton.rawValue):
            cell.textLabel?.text = "Continue"
            cell.textLabel?.textColor = .nordic
            cell.textLabel?.numberOfLines = 1
            cell.textLabel?.textAlignment = .center
            cell.accessoryType = .none
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath {
        case IndexPath(row: 0, section: Section.links.rawValue):
            open(url: "https://www.nordicsemi.com/Software-and-Tools/Software/nRF-Connect-SDK")
        case IndexPath(row: 1, section: Section.links.rawValue):
            open(url: "https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/zephyr/samples/subsys/mgmt/mcumgr/smp_svr/README.html")
        case IndexPath(row: 2, section: Section.links.rawValue):
            open(url: "https://github.com/nordicsemi/IOS-nRF-Connect-Device-Manager")
        case IndexPath(row: 0, section: Section.continueButton.rawValue):
            dismiss(animated: true)
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .links:
            return "Links"
        case .header, .body, .continueButton:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .header, .body, .links:
            return nil
        case .continueButton:
            return Bundle.main.releaseVersionNumberPretty
        }
    }
}

// MARK: - IntroViewController

private extension IntroViewController {
    
    func open(url: String) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// MARK: - Bundle Extension

private extension Bundle {
    
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    var releaseVersionNumberPretty: String {
        return "Version \(releaseVersionNumber ?? "1.0") (\(buildVersionNumber ?? "1"))"
    }
}
