//
//  CustomToastView.swift
//  BeMe
//
//  Created by Yunjae Kim on 2021/01/15.
//

import UIKit

class ToastView: UIView {
    private var toastBackground: UIImageView = UIImageView().then {
        $0.image = UIImage(named: "imgToast")
    }
    private var toastLabel: UILabel = UILabel().then {
        $0.font = UIFont(name: "GmarketSansTTFMedium", size: 14)
        $0.textColor = .white
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

