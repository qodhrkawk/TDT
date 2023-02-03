//
//  CustomToastView.swift
//  BeMe
//
//  Created by Yunjae Kim on 2021/01/15.
//

import UIKit

class ToastView: UIView {
    private var toastBackground: UIImageView = UIImageView().then {
        $0.image = UIImage(named: "imgToast")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = UIColor(named: "typingTextColor")?.withAlphaComponent(0.7)
    }
    private var toastLabel: UILabel = UILabel().then {
        $0.font = UIFont(name: "GmarketSansTTFMedium", size: 14)
        $0.textColor = UIColor(named: "boxColor")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout(){
        self.addSubview(toastBackground)
        self.addSubview(toastLabel)
        
        toastBackground.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }
        
        toastLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    func setLabel(text: String){
        toastLabel.text = text
    }
}

