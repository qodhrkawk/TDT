//
//  FlickEmptyView.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/28.
//

import UIKit

class FlickEmptyView: UIView {

    
    var titleLabel = UILabel().then{
        $0.text = "혹시 잊고 있던 할 일이 있지 않나요?"
        $0.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        $0.textAlignment = .center
        $0.textColor = .brownGreyTwo
        $0.alpha = 0.4
    }
    var emoji = UIImageView().then {
        $0.image = UIImage(named: "imgEmptyMain")
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        addView()
        setAutoLayout()
        
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    
    }
    
    func addView(){
        self.addSubview(titleLabel)
        self.addSubview(emoji)

    }
    func setAutoLayout(){
        emoji.snp.makeConstraints{
            $0.top.equalToSuperview()
            $0.width.height.equalTo(31)
            $0.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints{
            $0.top.equalTo(emoji.snp.bottom).offset(14)
            $0.centerX.equalToSuperview()
        }
        
        
    }
}
