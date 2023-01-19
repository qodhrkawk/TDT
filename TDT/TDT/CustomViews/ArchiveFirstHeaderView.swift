//
//  FirstHeaderView.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import UIKit

class ArchiveFirstHeaderView: UIView {
    private var dateLabel = UILabel().then {
        $0.text = ""
        $0.font = UIFont(name: "GmarketSansTTFLight", size: 12)
        $0.textColor = .brownGreyTwo
    }
    
    private var highLightView = UIView().then {
        if let mainColorIndex = UserDefaults.standard.value(forKey: "mainColor") as? Int {
            $0.backgroundColor = TodoVC.colors[mainColorIndex]
            $0.alpha = 0.2
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear

        if let mainColorIndex = UserDefaults.standard.value(forKey: "mainColor") as? Int {
            highLightView.backgroundColor = TodoVC.colors[mainColorIndex]
        }
        
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout(){
        self.addSubview(dateLabel)
        self.addSubview(highLightView)

        dateLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(6)
            $0.leading.equalToSuperview().offset(23)
        }
        highLightView.snp.makeConstraints{
            $0.bottom.equalTo(dateLabel.snp.bottom)
            $0.leading.equalTo(dateLabel)
            $0.height.equalTo(9)
            $0.trailing.equalTo(self.dateLabel)
        }
    }
    
    func startAnimation(){
        self.highLightView.snp.remakeConstraints{
            $0.bottom.equalTo(self.dateLabel.snp.bottom)
            $0.leading.equalTo(self.dateLabel)
            $0.height.equalTo(9)
            $0.trailing.equalTo(self.dateLabel)
            
        }
        self.alpha = 0
        UIView.animate(withDuration: 5.0, animations: {
            self.alpha = 1
        })
    }
    
    func setDate(date: String){
        dateLabel.text = date
    }
}
