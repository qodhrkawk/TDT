//
//  CustomToastView.swift
//  BeMe
//
//  Created by Yunjae Kim on 2021/01/15.
//

import UIKit

class ToastView: UIView {
    private var toastBackground: UIImageView = UIImageView().then {
        // 크기가 문구에 따라 늘어나므로 캡슐 모서리가 뭉개지지 않게 리사이저블로
        $0.image = UIImage(named: "imgToast")?
            .resizableImage(withCapInsets: UIEdgeInsets(top: 17, left: 17, bottom: 17, right: 17), resizingMode: .stretch)
            .withRenderingMode(.alwaysTemplate)
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
        
        // 라벨이 토스트 크기를 결정한다 — 좌우 20pt / 상하 10pt 여백
        toastLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.top.equalToSuperview().offset(10)
            $0.bottom.equalToSuperview().offset(-10)
        }
    }
    
    func setLabel(text: String){
        toastLabel.text = text
    }
}

