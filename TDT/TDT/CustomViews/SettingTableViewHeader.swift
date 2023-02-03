//
//  SettingTableViewHeader.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/02/02.
//

import UIKit
import SnapKit

class SettingTableViewHeader: UIView {
    private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = Design.titleFont
        titleLabel.textColor = Design.titleTextColor
        
        return titleLabel
    }()
    
    private var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = Design.subtitleFont
        subTitleLabel.textColor = Design.subtitleTextColor
        
        return subTitleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUIs()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTitle(titleText: String, subtitleText: String) {
        titleLabel.text = titleText
        subTitleLabel.text = subtitleText
    }
    
    private func setupUIs() {
        backgroundColor = Design.backgroundColor

        addSubview(titleLabel)
        addSubview(subTitleLabel)
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(16)
        }
        
        subTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
    }
}

extension SettingTableViewHeader {
    private enum Design {
        static let backgroundColor = UIColor(named: "bgColor")

        static let titleFont = UIFont(name: "GmarketSansTTFMedium", size: 15)?.withFigmaFontSize(500)
        static let subtitleFont = UIFont(name: "GmarketSansTTFMedium", size: 14)?.withFigmaFontSize(500)
        
        static let titleTextColor = UIColor(named: "mainText")
        static let subtitleTextColor = UIColor(named: "subText")
    }
}

