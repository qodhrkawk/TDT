//
//  ArchiveTableViewCell.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import UIKit
import Combine

class ArchiveTableViewCell: UITableViewCell {
    static let identifier = "ArchiveTableViewCell"
    
    @IBOutlet weak var containView: UIView!
    @IBOutlet weak var todoLabel: UILabel!
    @IBOutlet weak var gradientView: ReverseGradientView!
    
    weak var textBoxDelegate: TextBoxDelegate?
    var wasSingleTapped = false
    private var isRestoring = false
    @Published var todoData: TodoData?
    @Published var isToday: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var mainColor: UIColor {
        guard let currentTheme = ThemeManager.shared.currentTheme else { return Theme.flickBlue.mainColor }
        return currentTheme.mainColor
    }

    private var doubletap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
    private var singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
    private var rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwiped))
    private var leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwiped))
    private var feedbackGenerator: UIImpactFeedbackGenerator?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUIs()
        subscribeAttributes()
        prepareFeedbackGenerator()
    }

    override func prepareForReuse() {
        wasSingleTapped = false

        setupUIs()
        subscribeAttributes()
        prepareFeedbackGenerator()
    }
}

extension ArchiveTableViewCell {
    private func subscribeAttributes() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        
        $todoData.sink(receiveValue: { [weak self] todoData in
            guard
                let self,
                let todoData
            else { return }
            
            if todoData.isImportant {
                self.containView.setBorder(borderColor: self.mainColor, borderWidth: 1.5)
            }
            else {
                self.containView.setBorder(borderColor: self.mainColor, borderWidth: 0.0)
            }

            self.setLabel(text: todoData.todo)
        })
        .store(in: &cancellables)
        
        $isToday.sink(receiveValue: { [weak self] isToday in
            if isToday {
                self?.todoLabel.textColor = Design.todayTextColor
            }
        })
        .store(in: &cancellables)
    }
    
    private func setupUIs(){
        backgroundColor = Design.backgroundColor
        
        gradientView.alpha = 0
        
        containView.backgroundColor = Design.boxColor
        containView.makeRounded(cornerRadius: 8)
        containView.isUserInteractionEnabled = true
     
        doubletap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
        
        rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwiped))
        leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwiped))
        
        rightSwipe.direction = .right
        leftSwipe.direction = .left
        
        singleTap.numberOfTapsRequired = 1
        doubletap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubletap)
        containView.addGestureRecognizer(doubletap)
        containView.addGestureRecognizer(singleTap)
        addGestureRecognizer(rightSwipe)
    }
    
    private func prepareFeedbackGenerator() {
        feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator?.prepare()
    }

    @objc private func doubleTapped(){
        feedbackGenerator?.impactOccurred()
        textBoxDelegate?.doubleTapped(cell: self)
    }

    @objc private func leftSwiped(){
        textBoxDelegate?.shouldMove()
    }

    @objc private func rightSwiped(){
        guard !isRestoring else { return }
        isRestoring = true

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: { [weak self] in
            guard let self else { return }

            let slide = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
            self.gradientView.alpha = 1
            self.containView.transform = slide
            self.todoLabel.transform = slide
            self.gradientView.transform = slide
        }, completion: { [weak self] _ in
            guard let self else { return }

            // 애니메이션 완료 시점에 델리게이트가 indexPath(for:)로 실제 위치를 조회한다
            self.textBoxDelegate?.leftSwiped(cell: self)
            self.isRestoring = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self else { return }

                self.containView.transform = .identity
                self.todoLabel.transform = .identity
                self.gradientView.transform = .identity
                self.gradientView.alpha = 0
            }
        })
    }


    @objc private func singleTapped(){
        if !wasSingleTapped{
            wasSingleTapped = true
            textBoxDelegate?.longTapped(cell: self)
        }
    }
    
    private func setLabel(text: String){
        todoLabel.text = text
        todoLabel.font = Design.font
        todoLabel.lineBreakMode = .byCharWrapping
        
        todoLabel.setSpacing(spacing: 5, kernValue: -1)
        todoLabel.textColor = Design.textColor

        containView.snp.remakeConstraints{
            $0.leading.equalTo(todoLabel.snp.leading).offset(-18)
            $0.top.equalTo(todoLabel.snp.top).offset(-15)
            $0.bottom.equalTo(todoLabel.snp.bottom).offset(15)
            $0.trailing.equalTo(todoLabel.snp.trailing).offset(18)
        }
        
        gradientView.snp.remakeConstraints {
            $0.trailing.equalTo(containView.snp.leading).offset(18)
            $0.top.equalTo(containView.snp.top)
            $0.bottom.equalTo(containView.snp.bottom)
            $0.width.equalTo(75)
        }
    }
}

extension ArchiveTableViewCell {
    enum Design {
        static let backgroundColor = UIColor(named: "bgColor")
        static let boxColor = UIColor(named: "archiveBoxColor")
        
        static let font = UIFont(name: "GmarketSansTTFMedium", size: 15)?.withFigmaFontSize(500)
        static let textColor = UIColor(named: "doneText")
        static let todayTextColor = UIColor(named: "mainText")
    }
}
