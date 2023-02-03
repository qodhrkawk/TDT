//
//  EmptyView.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/19.
//

import UIKit
import Combine

enum EmptyViewType {
    case main
    case archive
    
    var titleText: String {
        switch self {
        case .main: return "할 일을 모두 완료했어요!"
        case .archive: return "앗, 아직 한 일들이 없네요!"
        }
    }
    
    var emojiImage: UIImage? {
        switch self {
        case .main: return UIImage(named: "imgEmptyMain")
        case .archive: return UIImage(named: "imgEmptyArchive")
        }
    }
}

class EmptyView: UIView {
    @Published private var type: EmptyViewType?

    private var cancellables = Set<AnyCancellable>()
    
    private var titleLabel = UILabel().then{
        $0.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        $0.textAlignment = .center
        $0.textColor = UIColor(named: "subText")
        $0.alpha = 0.4
    }

    private var emojiImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        setupLayout()
        subscribeVariables()
    }
    
    convenience init(type: EmptyViewType) {
        self.init(frame: .zero)
        self.type = type
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func subscribeVariables() {
        $type.sink(receiveValue: { [weak self] type in
            guard let self, let type else { return }
            self.titleLabel.text = type.titleText
            self.emojiImageView.image = type.emojiImage
        })
        .store(in: &cancellables)
    }
    
    private func setupLayout(){
        self.addSubview(titleLabel)
        self.addSubview(emojiImageView)

        emojiImageView.snp.makeConstraints{
            $0.top.equalToSuperview()
            $0.width.height.equalTo(47)
            $0.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints{
            $0.top.equalTo(emojiImageView.snp.bottom).offset(18)
            $0.centerX.equalToSuperview()
        }
    }
}

