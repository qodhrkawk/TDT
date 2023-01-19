//
//  FirstHeaderView.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import UIKit

class FirstHeaderView: UIView {
    private var dateLabel = UILabel().then {
        $0.font = UIFont(name: "GmarketSansTTFLight", size: 12)
        $0.textColor = .brownGreyTwo
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout(){
        self.addSubview(dateLabel)

        dateLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(6)
            $0.leading.equalToSuperview().offset(23)
        }
    }
    
    func setDate(date: String){
        dateLabel.text = date
    }
}
