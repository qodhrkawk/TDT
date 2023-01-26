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
    @IBOutlet weak var gradientView: GradientView!
    
    weak var textBoxDelegate: TextBoxDelegate?
    var myIndexpath: IndexPath?
    var wasLongTapped = false
    @Published var todoData: TodoData?
    @Published var isToday: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var mainColor: UIColor {
        guard let currentTheme = ThemeManager.shared.currentTheme else { return Theme.blue.mainColor }
        return currentTheme.mainColor
    }

    private var doubletap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
    private var longtap = UILongPressGestureRecognizer(target: self, action: #selector(longTapped))
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
        wasLongTapped = false

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
        longtap = UILongPressGestureRecognizer(target: self, action: #selector(longTapped))
        longtap.minimumPressDuration = 0.5
        
        rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwiped))
        leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwiped))
        
        rightSwipe.direction = .right
        leftSwipe.direction = .left
        
        doubletap.numberOfTapsRequired = 2
        containView.addGestureRecognizer(doubletap)
        containView.addGestureRecognizer(longtap)
        addGestureRecognizer(rightSwipe)
    }
    
    private func prepareFeedbackGenerator() {
        feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator?.prepare()
    }

    @objc private func doubleTapped(){
        feedbackGenerator?.impactOccurred()
        textBoxDelegate?.doubleTapped(indexPath: myIndexpath!)
    }
    
    @objc private func leftSwiped(){
        textBoxDelegate?.shouldMove()
    }
    
    @objc private func rightSwiped(){
    
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self else { return }

            self.gradientView.alpha = 1
            self.containView.transform = CGAffineTransform(translationX: 50, y: 0)
            self.todoLabel.transform = CGAffineTransform(translationX: 50, y: 0)
            self.gradientView.transform = CGAffineTransform(translationX: 50, y: 0)
        })
        UIView.animate(withDuration: 0.5,delay: 0.2,options: .curveEaseIn, animations: { [weak self] in
            guard let self else { return }

            self.transform = CGAffineTransform(translationX: 400, y: 0)
            self.containView.transform = CGAffineTransform(translationX: 400, y: 0)
            self.todoLabel.transform = CGAffineTransform(translationX: 400, y: 0)
            self.gradientView.transform = CGAffineTransform(translationX: 400, y: 0)
        }, completion: { finish in
            self.textBoxDelegate?.leftSwiped(indexPath: self.myIndexpath!)
            UIView.animate(withDuration: 0,delay: 0.3, animations: { [weak self] in
                guard let self else { return }

                self.containView.transform = .identity
                self.todoLabel.transform = .identity
                self.gradientView.transform = .identity
                self.gradientView.alpha = 0
            })
        })
    }
    
   
    @objc private func longTapped(){
        if !wasLongTapped{
            wasLongTapped = true
            textBoxDelegate?.longTapped(indexPath: myIndexpath!)
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
        static let todayTextColor = UIColor.mainText
    }
}
