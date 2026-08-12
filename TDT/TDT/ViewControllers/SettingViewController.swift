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
    
    // 문의 처리에 필요한 기기 정보 — 본문 하단에 미리 채워둔다
    private var supportMailBody: String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        return "\n\n\n--------\nFlick v\(appVersion) / iOS \(UIDevice.current.systemVersion) / \(UIDevice.current.model)"
    }

    private func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setSubject(Constants.supportMailSubject)
        mailComposerVC.setToRecipients([Constants.supportEmail])
        mailComposerVC.setMessageBody(supportMailBody, isHTML: false)

        return mailComposerVC
    }

    // Apple Mail 계정이 없는 기기에서 canSendMail()이 false를 반환하면
    // 아무 반응이 없던 버그 수정 — mailto:(기본 메일 앱) → 주소 복사 순으로 폴백한다.
    @objc private func showMailViewController() {
        if MFMailComposeViewController.canSendMail() {
            self.present(configuredMailComposeViewController(), animated: true, completion: nil)
            return
        }

        var components = URLComponents(string: "mailto:\(Constants.supportEmail)")
        components?.queryItems = [
            URLQueryItem(name: "subject", value: Constants.supportMailSubject),
            URLQueryItem(name: "body", value: supportMailBody)
        ]

        guard let mailtoURL = components?.url else {
            showCopyEmailAlert()
            return
        }

        UIApplication.shared.open(mailtoURL) { [weak self] success in
            if !success {
                DispatchQueue.main.async { self?.showCopyEmailAlert() }
            }
        }
    }

    private func showCopyEmailAlert() {
        let alert = UIAlertController(
            title: "메일 앱을 열 수 없어요",
            message: "아래 주소로 문의를 보내주세요.\n\(Constants.supportEmail)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "주소 복사", style: .default) { [weak self] _ in
            UIPasteboard.general.string = Constants.supportEmail
            self?.showToast(text: "이메일 주소를 복사했어요", withDelay: 0.3)
        })
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        present(alert, animated: true)
    }
}

extension SettingViewController {
    private enum Constants {
        static let titleTexts = ["화면 스타일", "테마","1:1 문의하기"]
        static let subtitleTexts = ["어떤 모드를 따를지 설정합니다.", "하이라이트 색상이 변경됩니다.", "누르면 메일 앱으로 이동합니다."]

        static let supportEmail = "theteamkarry@gmail.com"
        static let supportMailSubject = "Flick 1:1 문의하기"
    }
}

extension SettingViewController {
    private enum Design {
        static let backgroundColor = UIColor(named: "bgColor")
        static let settingsImage = UIImage(named: "imgSettings")?.withRenderingMode(.alwaysTemplate)
        
        static let mainTextColor = UIColor(named: "mainText")
    }
}
