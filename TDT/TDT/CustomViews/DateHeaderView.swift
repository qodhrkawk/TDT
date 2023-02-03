//
//  DateHeaderView.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import UIKit

class DateHeaderView: UIView {
    private var dateLabel = UILabel().then {
        $0.font = UIFont(name: "GmarketSansTTFLight", size: 12)?.withFigmaFontSize(500)
        $0.textColor = UIColor(named: "subText")
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
            $0.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(20)
        }
    }
    
    func setDate(date: String){
        dateLabel.text = date
    }
    
    func highlightDateLabel() {
        guard let currentTheme = ThemeManager.shared.currentTheme else { return }
        dateLabel.textColor = currentTheme.mainColor
    }
}
