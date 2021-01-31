//
//  ArchiveTVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import UIKit

class ArchiveTVC: UITableViewCell {
    static let identifier = "ArchiveTVC"
    
    @IBOutlet weak var containView: UIView!
    @IBOutlet weak var todoLabel: UILabel!
    @IBOutlet weak var deleteImage: UIImageView!
    
    var todo: String?
    var indexPathRow = 0
    var isImportant = false
    var textBoxDelegate: TextBoxDelegate?
    var containViewOrigin: CGFloat?
    var todoLabelOrigin: CGFloat?
    var myIndexpath: IndexPath?
    var feedbackGenerator: UIImpactFeedbackGenerator?
    

    var doubletap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
    var longtap = UILongPressGestureRecognizer(target: self, action: #selector(longTapped))
    var rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwiped))
    var leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwiped))
    
    let highLightView = UIView().then {
        $0.backgroundColor = TodoVC.mainColor
        $0.roundCorners(cornerRadius: 3.0, maskedCorners: [.layerMinXMinYCorner, .layerMinXMaxYCorner])
    }

    var wasLongTapped = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = .veryLightPinkTwo
        setItems()
        todoLabelOrigin = todoLabel.center.x
        containViewOrigin = containView.center.x
        deleteImage.alpha = 0
        
        self.feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        self.feedbackGenerator?.prepare()
        
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
      
        // Configure the view for the selected state
    }
    override func prepareForReuse() {
        wasLongTapped = false
        self.backgroundColor = .veryLightPinkTwo
        setItems()
        
        todoLabelOrigin = todoLabel.center.x
        containViewOrigin = containView.center.x
        deleteImage.alpha = 0
        
        self.feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        self.feedbackGenerator?.prepare()
        
    }

    func setItems(){
        
        containView.backgroundColor = .subgrey
        
        
        containView.makeRounded(cornerRadius: 3)
        self.makeRounded(cornerRadius: 3)
        
        

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
        self.addGestureRecognizer(rightSwipe)
//        self.addGestureRecognizer(leftSwipe)
//        containView.addGestureRecognizer(panTap)
        self.addSubview(highLightView)
        highLightView.snp.makeConstraints{
            $0.leading.top.bottom.equalTo(containView)
            $0.width.equalTo(7)
        }
        
        if !isImportant {
            highLightView.alpha = 0
        }
        else{
            highLightView.alpha = 1
        }
       
      
    }
    

    func changeImportant(){
        print("callled")
        if isImportant {
            UIView.animate(withDuration: 0.5, animations: {
                self.highLightView.alpha = 0
            })
           
            isImportant = false
        }
        else{
            
            UIView.animate(withDuration: 0.5, animations: {
                self.highLightView.alpha = 1
            })
            isImportant = true
        }
        
    }
    @objc func doubleTapped(){
        print("더블클릭")
        feedbackGenerator?.impactOccurred()
        
        
     
        textBoxDelegate?.doubleTapped(idx: myIndexpath!)
       
    }
    @objc func leftSwiped(){
        self.textBoxDelegate?.shouldMove()
    }
    
    @objc func rightSwiped(){
        print("오른스와이프")
        print(myIndexpath!)
        deleteImage.image = UIImage(named: "imgOops")
        UIView.animate(withDuration: 0.4, animations: {
            self.deleteImage.alpha = 1
            self.containView.transform = CGAffineTransform(translationX: 50, y: 0)
            self.todoLabel.transform = CGAffineTransform(translationX: 50, y: 0)
            self.deleteImage.transform = CGAffineTransform(translationX: 50, y: 0)
            self.highLightView.transform = CGAffineTransform(translationX: 50, y: 0)
            
            
        }, completion: { finish in
          
        })
        UIView.animate(withDuration: 0.3,delay: 0.3,options: .curveEaseIn, animations: {
            
            self.containView.transform = CGAffineTransform(translationX: 400, y: 0)
            self.todoLabel.transform = CGAffineTransform(translationX: 400, y: 0)
            self.deleteImage.transform = CGAffineTransform(translationX: 400, y: 0)
            self.highLightView.transform = CGAffineTransform(translationX: 400, y: 0)
            
        }, completion: { finish in
            self.textBoxDelegate?.leftSwiped(idx: self.myIndexpath!)
            UIView.animate(withDuration: 0,delay: 0.3, animations: {
                self.deleteImage.alpha = 0
                self.containView.transform = .identity
                self.todoLabel.transform = .identity
                self.deleteImage.transform = .identity
                self.highLightView.transform = .identity
            })
          
            
        })

       
    }
    
   
    @objc func longTapped(){
        print("long tapped")
//        if longtap.state == UIGestureRecognizer.State.began{
//            textBoxDelegate?.longTapped(idx: myIndexpath!)
//        }
        if !wasLongTapped{
            wasLongTapped = true
            textBoxDelegate?.longTapped(idx: myIndexpath!)
            
        }
        
//        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
//        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)

        
        
    }
    
    func setLabelColor(){
        
        todoLabel.textColor = .brownGreyTwo
    }
    
    func setLabel(str: String){
        todoLabel.text = str
        todoLabel.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        todoLabel.lineBreakMode = .byCharWrapping
        
        todoLabel.setSpacing(spacing: 8, kernValue: -1)
        
        let viewWidth = todoLabel.intrinsicContentSize.width
        
        
        todoLabel.textColor = .brownGreyThreeBlur
        
        
        containView.snp.remakeConstraints{
            $0.leading.equalTo(todoLabel.snp.leading).offset(-19)
            $0.top.equalTo(todoLabel.snp.top).offset(-16)

            
            var maximumIntrinsic = CGFloat(0.0)
       
            var strArr = getLinesArrayFromLabel(label: todoLabel)
            var tmpLabel = UILabel()
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
            
            
         
            
            
            $0.height.equalTo(27 + 18 + 25 * (todoLabel.calculateMaxLines()-1))
            
        }
        todoLabelOrigin = todoLabel.center.x
        containViewOrigin = containView.center.x
        
        
        
    }
    
    func showDelete(){
        print("지우자지우자")
        
        
        
    }
    
    func getLinesArrayFromLabel(label:UILabel) -> [String] {
        
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
