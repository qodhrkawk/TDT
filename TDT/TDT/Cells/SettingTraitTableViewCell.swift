//
//  SettingTraitTableViewCell.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/02/02.
//

import UIKit

class SettingTraitTableViewCell: UITableViewCell {
    static let identifier = "SettingTraitTableViewCell"

    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var traitImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkImageView: UIImageView!
    
    private var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Design.separatorColor
        return view
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUIs()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setupUIs()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setTraitInfo(traitInfo: TraitInfo) {
        titleLabel.text = traitInfo.text
        traitImageView.image = traitInfo.image
    }
    
    func setSelectedTrait() {
        checkImageView.alpha = 1
    }
    
    func addSeparator() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalToSuperview().offset(-1)
            $0.height.equalTo(1)
        }
    }
}

extension SettingTraitTableViewCell {
    private func setupUIs() {
        backgroundColor = Design.backgroundColor
        checkImageView.alpha = 0
        checkImageView.image = Design.checkImage
        checkImageView.tintColor = Design.checkImageTintColor

        titleLabel.font = Design.titleFont
        titleLabel.textColor = Design.titleTextColor
        
        imageContainerView.setBorder(borderColor: Design.imageContainerBorderColor, borderWidth: 1.0)
        imageContainerView.makeRounded(cornerRadius: 5)
        imageContainerView.backgroundColor = Design.backgroundColor
        
        traitImageView.makeRounded(cornerRadius: 5)
        traitImageView.backgroundColor = Design.backgroundColor
        
        removeSeparator()
    }
    
    private func removeSeparator() {
        separatorView.removeFromSuperview()
    }
}

extension SettingTraitTableViewCell {
    private enum Design {
        static let backgroundColor = UIColor(named: "bgColor")
        static let titleFont = UIFont(name: "GmarketSansTTFMedium", size: 14)?.withFigmaFontSize(500)
        static let titleTextColor = UIColor(named: "mainText")
        
        static let checkImage = UIImage(named: "imgCheck")?.withRenderingMode(.alwaysTemplate)
        static let checkImageTintColor = UIColor(named: "mainText")
        
        static let imageContainerBorderColor = UIColor(named: "typingTextColor")?.withAlphaComponent(0.1)
        static let separatorColor = UIColor(named: "typingTextColor")?.withAlphaComponent(0.06)
    }
}
