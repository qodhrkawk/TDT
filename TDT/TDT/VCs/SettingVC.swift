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
    
    @IBOutlet weak var underView: UIView!
    let defaults = UserDefaults.standard
    var settingImageNames = ["imgSettings","imgSettingsGr","imgSettingsYl","imgSettingsPk"]
    
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
            line.backgroundColor = .duckEggBlue
        }
        
    }
    
    func setLabels(){
        for lb in titleLabels {
            lb.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        }
        
        for lb in subLabels {
            lb.font = UIFont(name: "GmarketSansTTFMedium", size: 14)
            lb.textColor = .brownGreyTwo
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
        underView.backgroundColor = .veryLightPinkFive
        
    }
    func setMainColor(){
        if let mainColorIndex = defaults.value(forKey: "mainColor") as? Int {
            let settingImageName = settingImageNames[mainColorIndex]
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
        mailComposerVC.setToRecipients(["yeseul2y@gmail.com"])
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
    
}

