//
//  SettingListTableViewCell.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/31.
//

import UIKit

class SettingListTableViewCell: UITableViewCell {
    static let identifier = "SettingListTableViewCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUIs()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupTitle(titleText: String, subtitleText: String) {
        titleLabel.text = titleText
        subTitleLabel.text = subtitleText
    }
}

extension SettingListTableViewCell {
    private func setupUIs() {
        backgroundColor = Design.backgroundColor

        titleLabel.font = Design.titleFont
        titleLabel.textColor = Design.titleTextColor
        
        subTitleLabel.font = Design.subtitleFont
        subTitleLabel.textColor = Design.subtitleTextColor
    }
}

extension SettingListTableViewCell {
    private enum Design {
        static let backgroundColor = UIColor(named: "bgColor")

        static let titleFont = UIFont(name: "GmarketSansTTFMedium", size: 15)?.withFigmaFontSize(500)
        static let subtitleFont = UIFont(name: "GmarketSansTTFMedium", size: 14)?.withFigmaFontSize(500)
        
        static let titleTextColor = UIColor(named: "mainText")
        static let subtitleTextColor = UIColor(named: "subText")
    }
}
