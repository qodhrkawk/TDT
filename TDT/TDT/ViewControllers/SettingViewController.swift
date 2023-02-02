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
    @IBOutlet weak var settingListTableView: UITableView!
    @IBOutlet weak var themeTableView: UITableView!
    @IBOutlet weak var closeButton: UIButton!
    
    private var selectedThemeIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIs()
        setupTableViews()
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension SettingViewController {
    private func setupUIs() {
        view.backgroundColor = Design.backgroundColor
        settingListTableView.backgroundColor = Design.backgroundColor
        themeTableView.backgroundColor =  Design.backgroundColor
        settingsImageView.image = Design.settingsImage
        settingsImageView.tintColor = Design.mainTextColor
        
        closeButton.tintColor = Design.mainTextColor
    }
    
    private func setupTableViews() {
        settingListTableView.delegate = self
        settingListTableView.dataSource = self
        settingListTableView.contentInset = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
        
        themeTableView.delegate = self
        themeTableView.dataSource = self
        themeTableView.contentInset = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
    }
}

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case settingListTableView:
            return 72
        default:
            return 48
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case settingListTableView:
            if indexPath.row == 0 {
                let mailComposeViewController = self.configuredMailComposeViewController()

                if MFMailComposeViewController.canSendMail() {
                    self.present(mailComposeViewController, animated: true, completion: nil)
                }
            }
        default:
            themeChanged(theme: Theme.allCases[indexPath.row])
        }
    }
}

extension SettingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case settingListTableView:
            return 2
        default:
            return Theme.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case settingListTableView:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SettingListTableViewCell.identifier
            ) as? SettingListTableViewCell else { return UITableViewCell() }

            cell.setupTitle(
                titleText: Constants.titleTexts[indexPath.row],
                subtitleText: Constants.subtitleTexts[indexPath.row]
            )

            return cell
        default:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ThemeTableViewCell.identifier
            ) as? ThemeTableViewCell else { return UITableViewCell() }
            
            let theme = Theme.allCases[indexPath.row]
            cell.setTheme(theme: theme)
            cell.delegate = self
            if ThemeManager.shared.currentTheme == theme {
                cell.setSelectedTheme()
            }
            
            return cell
        }
    }
}

extension SettingViewController: ThemeTableViewCellDelegate {
    func themeChanged(theme: Theme) {
        ThemeManager.shared.setCurrentTheme(theme)
        themeTableView.reloadData()
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
            completion: {
            self.showToast(text: "전송 완료", withDelay: 2.0)
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
}

extension SettingViewController {
    private enum Constants {
        static let titleTexts = ["1:1 문의하기", "테마"]
        static let subtitleTexts = ["누르면 메일 앱으로 이동합니다.", "하이라이트 색상이 변경됩니다."]
    }
}

extension SettingViewController {
    private enum Design {
        static let backgroundColor = UIColor(named: "bgColor")
        static let settingsImage = UIImage(named: "imgSettings")?.withRenderingMode(.alwaysTemplate)
        
        static let mainTextColor = UIColor(named: "mainText")
    }
}
