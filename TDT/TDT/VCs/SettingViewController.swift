//
//  SettingViewController.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/02/01.
//

import UIKit
import MessageUI


class SettingViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var settingImage: UIImageView!
    @IBOutlet var titleLabels: [UILabel]!
    @IBOutlet var subLabels: [UILabel]!
    
    @IBOutlet var sepLines: [UIView]!
    
    @IBOutlet var colorButtons: [UIButton]!
    
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var underView: UIView!

    private let userDefaults = UserDefaults.standard

    private var settingImageNames = Constants.settingImageNames
    private var darkSettingImageNames = Constants.darkSettingImageNames
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIs()
    }

    override func viewWillAppear(_ animated: Bool) {
        setMainColor()
    }
    
    private func setupUIs(){
        sepLines.forEach { $0.backgroundColor = Design.Color.separateLineColor }

        self.view.backgroundColor = Design.Color.viewBackgroundColor

        if traitCollection.userInterfaceStyle == .light {
            cancelButton.setImage(Design.Image.closeButtonImage, for: .normal)
        }
        else {
            cancelButton.setImage(Design.Image.darkCloseButtonImage, for: .normal)
        }
        
        setupLabels()
        setupButtons()
    }
    
    private func setupLabels(){
        for titleLabel in titleLabels {
            titleLabel.font = Design.Font.titleLabelFont
            titleLabel.textColor = Design.Color.titleLabelTextColor
        }
        
        for sublabel in subLabels {
            sublabel.font = Design.Font.subLabelFont
            sublabel.textColor = Design.Color.subLabelTextColor
        }
    }
    
    private func setupButtons(){
        for index in 0..<colorButtons.count {
            colorButtons[index].makeRounded(cornerRadius: 17.5)
            colorButtons[index].backgroundColor = TodoVC.colors[index]

            if TodoVC.mainColor == TodoVC.colors[index] {
                colorButtons[index].alpha = 1
            }
            else {
                colorButtons[index].alpha = 0.2
            }
        }
        
        if traitCollection.userInterfaceStyle == .light {
            moreButton.setImage(Design.Image.moreButtonImage, for: .normal)
        }
        else {
            moreButton.setImage(Design.Image.darkMoreButtonImage, for: .normal)
        }
        
        underView.backgroundColor = Design.Color.underViewColor
    }

    private func setMainColor(){
        if let mainColorIndex = userDefaults.value(forKey: "mainColor") as? Int {
            var settingImageName = settingImageNames[mainColorIndex]
            if traitCollection.userInterfaceStyle == .dark {
                settingImageName = darkSettingImageNames[mainColorIndex]
            }
            settingImage.image = UIImage(named: settingImageName)
        }
    }
    
    @IBAction func colorButtonAction(_ sender: UIButton) {
        switch sender {
        case colorButtons[0]:
            TodoVC.mainColor = TodoVC.colors[0]
            userDefaults.setValue(0, forKey: "mainColor")
        case colorButtons[1]:
            TodoVC.mainColor = TodoVC.colors[1]
            userDefaults.setValue(1, forKey: "mainColor")
        case colorButtons[2]:
            TodoVC.mainColor = TodoVC.colors[2]
            userDefaults.setValue(2, forKey: "mainColor")
        case colorButtons[3]:
            TodoVC.mainColor = TodoVC.colors[3]
            userDefaults.setValue(3, forKey: "mainColor")
        default:
            return
        }
        
        setupButtons()
        setMainColor()
    }
    
    @IBAction func xButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func emailButtonAction(_ sender: Any) {
        let mailComposeViewController = self.configuredMailComposeViewController()

        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
    }

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
        mailComposerVC.setToRecipients(["flick.todo.official@gmail.com"])
        mailComposerVC.setMessageBody("", isHTML: false)

        return mailComposerVC
    }
}

extension SettingViewController {
    enum Design {
        enum Color {
            static let separateLineColor = UIColor(named: "inactiveColor")
            static let viewBackgroundColor = UIColor(named: "bgColor")
            static let titleLabelTextColor = UIColor(named: "typingTextColor")
            static let subLabelTextColor = UIColor(named: "mainTextColor")
            static let underViewColor = UIColor(named: "boxColor")
        }
        
        enum Image {
            static let closeButtonImage = UIImage(named: "btnClose")
            static let darkCloseButtonImage = UIImage(named: "dkBtnClose")
            static let moreButtonImage = UIImage(named: "btnMore")
            static let darkMoreButtonImage = UIImage(named: "dkBtnMore")
        }
        
        enum Font {
            static let titleLabelFont = UIFont(name: "GmarketSansTTFMedium", size: 15)
            static let subLabelFont = UIFont(name: "GmarketSansTTFMedium", size: 14)
        }

    }
    
    enum Constants {
        static let settingImageNames = ["imgSettings","imgSettingsGr","imgSettingsYl","imgSettingsPk"]
        static let darkSettingImageNames = ["dkImgSettings","dkImgSettingsGr","dkImgSettingsYl","dkImgSettingsPk"]
    }
}
