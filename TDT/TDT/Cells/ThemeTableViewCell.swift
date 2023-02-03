//
//  ThemeTableViewCell.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/31.
//

import UIKit

protocol ThemeTableViewCellDelegate: AnyObject {
    func themeChanged(theme: Theme)
}

class ThemeTableViewCell: UITableViewCell {
    static let identifier = "ThemeTableViewCell"

    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkImageView: UIImageView!
    
    private var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Design.separatorColor
        return view
    }()
    
    private var theme: Theme?
        
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
    
    func setTheme(theme: Theme) {
        self.theme = theme

        colorView.backgroundColor = theme.mainColor
        titleLabel.text = theme.colorName
    }
    
    func setSelectedTheme() {
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

extension ThemeTableViewCell {
    private func setupUIs() {
        backgroundColor = Design.backgroundColor
        checkImageView.alpha = 0
        checkImageView.image = Design.checkImage
        checkImageView.tintColor = Design.checkImageTintColor

        titleLabel.font = Design.titleFont
        titleLabel.textColor = Design.titleTextColor
        
        colorView.makeRounded(cornerRadius: 12)
        removeSeparator()
    }
    
    private func removeSeparator() {
        separatorView.removeFromSuperview()
    }
}


extension ThemeTableViewCell {
    private enum Design {
        static let backgroundColor = UIColor(named: "bgColor")
        static let titleFont = UIFont(name: "GmarketSansTTFMedium", size: 15)?.withFigmaFontSize(500)
        static let titleTextColor = UIColor(named: "mainText")
        
        static let checkImage = UIImage(named: "imgCheck")?.withRenderingMode(.alwaysTemplate)
        static let checkImageTintColor = UIColor(named: "mainText")
        static let separatorColor = UIColor(named: "typingTextColor")?.withAlphaComponent(0.06)
    }
}
