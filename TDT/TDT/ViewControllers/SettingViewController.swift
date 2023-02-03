//
//  SettingViewController.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/31.
//

import UIKit
import MessageUI

class SettingViewController: UIViewController {
    @IBOutlet weak var settingsImageView: UIImageView!
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var closeButton: UIButton!
    
    private var selectedThemeIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIs()
        setupTableViews()
        
        adjustToUserInterfaceStyle()
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension SettingViewController {
    private func setupUIs() {
        view.backgroundColor = Design.backgroundColor
        settingsTableView.backgroundColor =  Design.backgroundColor
        settingsImageView.image = Design.settingsImage
        settingsImageView.tintColor = Design.mainTextColor
        
        closeButton.tintColor = Design.mainTextColor
    }
    
    private func setupTableViews() {
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        settingsTableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    private func themeChanged(theme: Theme) {
        ThemeManager.shared.setCurrentTheme(theme)
        settingsTableView.reloadData()
    }
    
    private func traitChanged(traitInfo: TraitInfo) {
        TraitInfoManager.shared.setCurrentTraitInfo(traitInfo)
        settingsTableView.reloadData()
        adjustToUserInterfaceStyle()
    }
}

extension SettingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = SettingTableViewHeader(
            frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 68)
        )
        
        headerView.setupTitle(
            titleText: Constants.titleTexts[section],
            subtitleText: Constants.subtitleTexts[section]
        )
        
        if section == 2 {
            let gestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(showMailViewController)
            )
            headerView.addGestureRecognizer(gestureRecognizer)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 98
        case 1: return 48
        default: return 30
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            traitChanged(traitInfo: TraitInfo.allCases[indexPath.row])
        case 1:
            themeChanged(theme: Theme.allCases[indexPath.row])
        default:
            return
        }
    }
}

extension SettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        68
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return Theme.allCases.count
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SettingTraitTableViewCell.identifier
            ) as? SettingTraitTableViewCell else { return UITableViewCell() }
            
            let traitInfo = TraitInfo.allCases[indexPath.row]
            cell.setTraitInfo(traitInfo: traitInfo)

            if TraitInfoManager.shared.currentTraitInfo == traitInfo {
                cell.setSelectedTrait()
            }
            
            if indexPath.row < tableView.numberOfRows(inSection: indexPath.section) - 1 {
                cell.addSeparator()
            }
            
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ThemeTableViewCell.identifier
            ) as? ThemeTableViewCell else { return UITableViewCell() }
            
            let theme = Theme.allCases[indexPath.row]
            cell.setTheme(theme: theme)

            if ThemeManager.shared.currentTheme == theme {
                cell.setSelectedTheme()
            }
            
            if indexPath.row < tableView.numberOfRows(inSection: indexPath.section) - 1 {
                cell.addSeparator()
            }
            
            return cell
        default:
            let cell = UITableViewCell()
            cell.backgroundColor = Design.backgroundColor
            return cell
        }
    }
}

extension SettingViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(
            animated: true,
            completion: { [weak self] in
                guard let self else { return }
                switch result {
                case .cancelled: self.showToast(text: "취소되었어요", withDelay: 2.0)
                case .sent: self.showToast(text: "전송되었어요", withDelay: 2.0)
                default: break
                }
            
        })
    }
    
    private func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setSubject("Flick 1:1 문의하기")
        mailComposerVC.setToRecipients(["theteamkarry@gmail.com"])
        mailComposerVC.setMessageBody("", isHTML: false)

        return mailComposerVC
    }
    
    @objc private func showMailViewController() {
        let mailComposeViewController = self.configuredMailComposeViewController()
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
    }
}

extension SettingViewController {
    private enum Constants {
        static let titleTexts = ["화면 스타일", "테마","1:1 문의하기"]
        static let subtitleTexts = ["어떤 모드를 따를지 설정합니다.", "하이라이트 색상이 변경됩니다.", "누르면 메일 앱으로 이동합니다."]
    }
}

extension SettingViewController {
    private enum Design {
        static let backgroundColor = UIColor(named: "bgColor")
        static let settingsImage = UIImage(named: "imgSettings")?.withRenderingMode(.alwaysTemplate)
        
        static let mainTextColor = UIColor(named: "mainText")
    }
}
