//
//  TodoTableViewCell.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/22.
//

import UIKit
import Then
import SnapKit
import AudioToolbox
import Combine

class TodoTableViewCell: UITableViewCell {
    static let identifier = "TodoTableViewCell"
    
    @IBOutlet weak var containView: UIView!
    @IBOutlet weak var gradientView: GradientView!
    
    @IBOutlet weak var todoLabel: UILabel!
    
    var isImportant = false
    weak var textBoxDelegate: TextBoxDelegate?
    var myIndexpath: IndexPath?
    
    @Published var todoData: TodoData?
    
    private var cancellables = Set<AnyCancellable>()
    
    private var feedbackGenerator: UIImpactFeedbackGenerator?
    
    private var dragInitX : CGFloat?
    private var dragInitial = true

    private var doubletap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
    private var longtap = UILongPressGestureRecognizer(target: self, action: #selector(longTapped))
    private var leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwiped))
    
    private var mainColor: UIColor {
        guard let currentTheme = ThemeManager.shared.currentTheme else { return Theme.blue.mainColor }
        return currentTheme.mainColor
    }

    var wasLongTapped = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUIs()
        subscribeAttributes()
        prepareFeedbackGenerator()
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        gradientView.setGradient(color1: mainColor, color2: Design.backgroundColor!)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
      
    }
    override func prepareForReuse() {
        wasLongTapped = false
        setupUIs()
        subscribeAttributes()
                
        prepareFeedbackGenerator()
        layoutIfNeeded()
    }
    
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
    }

    private func setupUIs(){
        backgroundColor = Design.backgroundColor
        
        gradientView.alpha = 0
        
        containView.backgroundColor = Design.boxColor
        containView.makeRounded(cornerRadius: 8)
        containView.alpha = 1
        containView.isUserInteractionEnabled = true
        
        doubletap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        longtap = UILongPressGestureRecognizer(target: self, action: #selector(longTapped))
        longtap.minimumPressDuration = 0.5
        
        leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwiped))
        
        leftSwipe.direction = .left
        
        doubletap.numberOfTapsRequired = 2
        containView.addGestureRecognizer(doubletap)
        containView.addGestureRecognizer(longtap)
        addGestureRecognizer(leftSwipe)
    }
    
    private func prepareFeedbackGenerator() {
        feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator?.prepare()
    }
    
    @objc func doubleTapped(){
        feedbackGenerator?.impactOccurred()
        
        textBoxDelegate?.doubleTapped(indexPath: myIndexpath!)
    }
    
    @objc func leftSwiped(){
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self else { return }
            
            self.gradientView.alpha = 1
            self.containView.transform = CGAffineTransform(translationX: -50, y: 0)
            self.todoLabel.transform = CGAffineTransform(translationX: -50, y: 0)
            self.gradientView.transform = CGAffineTransform(translationX: -50, y: 0)
        })

        UIView.animate(withDuration: 0.5,delay: 0.2,options: .curveEaseOut, animations: { [weak self] in
            guard let self else { return }
            
            self.containView.transform = CGAffineTransform(translationX: -400, y: 0)
            self.todoLabel.transform = CGAffineTransform(translationX: -400, y: 0)
            self.gradientView.transform = CGAffineTransform(translationX: -400, y: 0)
            
        }, completion: { [weak self] finish in
            guard let self else { return }

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
   
    @objc func longTapped(){
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
            $0.leading.equalTo(containView.snp.trailing).offset(-18)
            $0.top.equalTo(containView.snp.top)
            $0.bottom.equalTo(containView.snp.bottom)
            $0.width.equalTo(75)
        }
    }
}

extension TodoTableViewCell {
    enum Design {
        static let backgroundColor = UIColor(named: "bgColor")
        static let boxColor = UIColor(named: "boxColor")
        
        static let font = UIFont(name: "GmarketSansTTFMedium", size: 15)?.withFigmaFontSize(500)
        static let textColor = UIColor(named: "mainText")
    }
}
