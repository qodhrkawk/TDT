//
//  SettingVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/02/01.
//

import UIKit
import MessageUI


class SettingVC: UIViewController, MFMailComposeViewControllerDelegate {
    

    @IBOutlet weak var settingImage: UIImageView!
    
 
    @IBOutlet var titleLabels: [UILabel]!
    
    @IBOutlet var subLabels: [UILabel]!
    

    @IBOutlet var sepLines: [UIView]!
    
    @IBOutlet var colorButtons: [UIButton]!
    
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var underView: UIView!
    let defaults = UserDefaults.standard
    var settingImageNames = ["imgSettings","imgSettingsGr","imgSettingsYl","imgSettingsPk"]
    var darkSettingImageNames = ["dkImgSettings","dkImgSettingsGr","dkImgSettingsYl","dkImgSettingsPk"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setItems()
        setLabels()
        setButtons()
    }
    override func viewWillAppear(_ animated: Bool) {
        setMainColor()
    }
    func setItems(){
        for line in sepLines {
            line.backgroundColor = UIColor(named: "inactiveColor")
        }
        self.view.backgroundColor = UIColor(named: "bgColor")
        if traitCollection.userInterfaceStyle == .light {
            cancelButton.setImage(UIImage(named: "btnClose"), for: .normal)
           
        }
        else {
            cancelButton.setImage(UIImage(named: "dkBtnClose"), for: .normal)
        }
    }
    
    func setLabels(){
        for lb in titleLabels {
            lb.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
            lb.textColor = UIColor(named: "typingTextColor")
        }
        
        for lb in subLabels {
            lb.font = UIFont(name: "GmarketSansTTFMedium", size: 14)
            lb.textColor = UIColor(named: "mainTextColor")
        }
        
    }
    
    func setButtons(){
        
        for i in 0...colorButtons.count-1 {
            colorButtons[i].makeRounded(cornerRadius: 17.5)
            colorButtons[i].backgroundColor = TodoVC.colors[i]
            if TodoVC.mainColor == TodoVC.colors[i] {
                colorButtons[i].alpha = 1
            }
            else {
                colorButtons[i].alpha = 0.2
            }
            
        }
        
        if traitCollection.userInterfaceStyle == .light {
            moreButton.setImage(UIImage(named: "btnMore"), for: .normal)
        }
        else {
            moreButton.setImage(UIImage(named: "dkBtnMore"), for: .normal)

        }
        
        underView.backgroundColor = UIColor(named: "boxColor")
        
    }
    func setMainColor(){
        if let mainColorIndex = defaults.value(forKey: "mainColor") as? Int {
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
            defaults.setValue(0, forKey: "mainColor")
            
        case colorButtons[1]:
            TodoVC.mainColor = TodoVC.colors[1]
            defaults.setValue(1, forKey: "mainColor")
        case colorButtons[2]:
            TodoVC.mainColor = TodoVC.colors[2]
            defaults.setValue(2, forKey: "mainColor")
        case colorButtons[3]:
            TodoVC.mainColor = TodoVC.colors[3]
            defaults.setValue(3, forKey: "mainColor")
        default:
            return
        
        
        }
        setButtons()
        setMainColor()
        
        
    }
    
    
    @IBAction func xButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setSubject("Flick 1:1 문의하기")
        mailComposerVC.setToRecipients(["flick.todo.official@gmail.com"])
        mailComposerVC.setMessageBody("", isHTML: false)
        return mailComposerVC
    }
    @IBAction func emailButtonAction(_ sender: Any) {
        let mailComposeViewController = self.configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
            print("can send mail")
        } 
    }
    func mailComposeController(_ controller: MFMailComposeViewController,
                              didFinishWith result: MFMailComposeResult, error: Error?) {
       
        
        controller.dismiss(animated: true, completion: {
            self.showToast(text: "전송 완료", withDelay: 2.0)
        })
    }


    
    
}

