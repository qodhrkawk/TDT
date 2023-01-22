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
    
    @IBOutlet weak var deleteImage: UIImageView!
    @IBOutlet weak var todoLabel: UILabel!
    
    var isImportant = false
    weak var textBoxDelegate: TextBoxDelegate?
    var myIndexpath: IndexPath?
    
    @Published var todoData: TodoData?
    
    private var cancellables = Set<AnyCancellable>()
    
    private var todo: String?
    private var indexPathRow = 0
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
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
      
    }
    override func prepareForReuse() {
        wasLongTapped = false
        setupUIs()
        subscribeAttributes()
                
        prepareFeedbackGenerator()
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
                self.containView.setBorder(borderColor: self.mainColor.withAlphaComponent(0.6), borderWidth: 1.5)
            }
            else {
                self.containView.setBorder(borderColor: self.mainColor.withAlphaComponent(0.6), borderWidth: 0.0)
            }
            
            self.setLabel(text: todoData.todo)
        })
        .store(in: &cancellables)
    }

    private func setupUIs(){
        backgroundColor = Design.backgroundColor
        deleteImage.alpha = 0

        containView.backgroundColor = UIColor(named: "boxColor")
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
        self.feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        self.feedbackGenerator?.prepare()
    }
    
    @objc func doubleTapped(){
        feedbackGenerator?.impactOccurred()
        
        textBoxDelegate?.doubleTapped(indexPath: myIndexpath!)
    }
    
    @objc func leftSwiped(){
        if traitCollection.userInterfaceStyle == .light {
            deleteImage.image = UIImage(named: "icnDone")
        }
        else {
            deleteImage.image = UIImage(named: "dkIcnDone")
        }
        
        UIView.animate(withDuration: 0.35, animations: { [weak self] in
            guard let self else { return }
            self.containView.backgroundColor = self.mainColor
        })
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            guard let self else { return }
            
            self.deleteImage.alpha = 1
            self.containView.transform = CGAffineTransform(translationX: -50, y: 0)
            self.todoLabel.transform = CGAffineTransform(translationX: -50, y: 0)
            self.deleteImage.transform = CGAffineTransform(translationX: -50, y: 0)
            
        }, completion: { finish in
            
        })
        UIView.animate(withDuration: 0.2,delay: 0.15,options: .curveEaseIn, animations: { [weak self] in
            guard let self else { return }
            
            self.containView.transform = CGAffineTransform(translationX: -400, y: 0)
            self.todoLabel.transform = CGAffineTransform(translationX: -400, y: 0)
            self.deleteImage.transform = CGAffineTransform(translationX: -400, y: 0)
            
        }, completion: { finish in
            self.textBoxDelegate?.leftSwiped(indexPath: self.myIndexpath!)
            UIView.animate(withDuration: 0,delay: 0.3, animations: { [weak self] in
                guard let self else { return }
                
                self.deleteImage.alpha = 0
                self.containView.transform = .identity
                self.todoLabel.transform = .identity
                self.deleteImage.transform = .identity
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
        todoLabel.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        todoLabel.lineBreakMode = .byCharWrapping
        
        todoLabel.setSpacing(spacing: 8, kernValue: -1)
        
        let viewWidth = todoLabel.intrinsicContentSize.width
        
        
        todoLabel.textColor = Design.textColor
        
        todoLabel.snp.remakeConstraints{
            $0.height.equalTo(20 + 25 * (todoLabel.calculateMaxLines()-1))
        }

        containView.snp.remakeConstraints{
            $0.leading.equalTo(todoLabel.snp.leading).offset(-19)
            $0.top.equalTo(todoLabel.snp.top).offset(-16)
            
            var maximumIntrinsic = CGFloat(0.0)
       
            let strArr = getLinesArrayFromLabel(label: todoLabel)
            let tmpLabel = UILabel()
            tmpLabel.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
            tmpLabel.addCharacterSpacing(kernValue: -1)
            
            for str in strArr {
                tmpLabel.text = str.replacingOccurrences(of: "\n", with: "")
                maximumIntrinsic = max(maximumIntrinsic,tmpLabel.intrinsicContentSize.width)
            }
    
            if maximumIntrinsic > 306 - 38{
                $0.width.equalTo(306)
            }
            else{
                
                $0.width.equalTo(38+maximumIntrinsic)
                
            }
            
            $0.height.equalTo(30 + 20 + 25 * (todoLabel.calculateMaxLines()-1))
        }
    }
    
    func getLinesArrayFromLabel(label: UILabel) -> [String] {
        let text:NSString = label.text! as NSString // TODO: Make safe?
        let font:UIFont = label.font
        let rect:CGRect = label.frame
        
        let myFont:CTFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        let attStr:NSMutableAttributedString = NSMutableAttributedString(string: text as String)
        attStr.addAttribute(NSAttributedString.Key(rawValue: String(kCTFontAttributeName)), value:myFont, range: NSMakeRange(0, attStr.length))
        let frameSetter:CTFramesetter = CTFramesetterCreateWithAttributedString(attStr as CFAttributedString)
        let path:CGMutablePath = CGMutablePath()
        path.addRect(CGRect(x:0, y:0, width:rect.size.width, height:100000))
        
        let frame:CTFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        let lines = CTFrameGetLines(frame) as NSArray
        var linesArray = [String]()
        
        for line in lines {
            let lineRange = CTLineGetStringRange(line as! CTLine)
            let range:NSRange = NSMakeRange(lineRange.location, lineRange.length)
            let lineString = text.substring(with: range)
            linesArray.append(lineString as String)
        }
        return linesArray
    }
    
}

extension TodoTableViewCell {
    enum Design {
        static let backgroundColor = UIColor(named: "bgColor")
        
        static let font = UIFont(name: "GmarketSansTTFMedium", size: 15)?.withFigmaFontSize(500)
        static let textColor = UIColor.mainText
    }
}
