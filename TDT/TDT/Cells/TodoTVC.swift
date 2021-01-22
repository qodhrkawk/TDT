//
//  TodoTVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/22.
//

import UIKit
import Then
import SnapKit

class TodoTVC: UITableViewCell {
    static let identifier = "TodoTVC"
    
    @IBOutlet weak var containView: UIView!
    
    @IBOutlet weak var deleteImage: UIImageView!
    @IBOutlet weak var todoLabel: UILabel!
    var todo: String?
    var indexPathRow = 0
    var isImportant = false
    var textBoxDelegate: TextBoxDelegate?
    
    let highLightView = UIView().then {
        $0.backgroundColor = .cyan
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        todoLabel.setLinespace(spacing: 8)
        self.backgroundColor = .veryLightPink
        setItems()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
      
        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
//        print(containView.frame)
    }
    
    func setItems(){
        containView.backgroundColor = .white
        containView.makeRounded(cornerRadius: 3)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(showDelete(_notification:)), name: "123", object: nil)
    
       
        containView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        let longtap = UILongPressGestureRecognizer(target: self, action: #selector(longTapped))
        tap.numberOfTapsRequired = 2
        containView.addGestureRecognizer(tap)
        containView.addGestureRecognizer(longtap)
        self.addSubview(highLightView)
        highLightView.snp.makeConstraints{
            $0.leading.top.bottom.equalTo(containView)
            $0.width.equalTo(7)
        }
        if !isImportant {
            highLightView.alpha = 0
        }
       
        
    }
    
    @objc func doubleTapped(){
        print("더블클릭")
        if isImportant {
            highLightView.alpha = 0
            isImportant = false
        }
        else{
            highLightView.alpha = 1
            isImportant = true
        }
    }
    
    @objc func longTapped(){
        print("long tapped")
        textBoxDelegate?.longTapped()
        
    }
    func setLabel(str: String){
        todoLabel.text = str
        todoLabel.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        todoLabel.addCharacterSpacing(kernValue: -1)
        todoLabel.lineBreakMode = .byCharWrapping
        
        let viewWidth = todoLabel.intrinsicContentSize.width
        
        
        
        
        print(viewWidth)
        print(todoLabel.intrinsicContentSize.height)
        
        
        
        
        
        
        
        containView.snp.remakeConstraints{
            $0.leading.equalTo(todoLabel.snp.leading).offset(-19)
            $0.top.equalTo(todoLabel.snp.top).offset(-16)
            //            $0.trailing.equalTo(todoLabel.snp.trailing).offset(19)
            //            $0.bottom.equalTo(todoLabel.snp.bottom).offset(16)
            
            
            var maximumIntrinsic = CGFloat(0.0)
            
            print(getLinesArrayFromLabel(label: todoLabel))
            var strArr = getLinesArrayFromLabel(label: todoLabel)
            var tmpLabel = UILabel()
            tmpLabel.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
            tmpLabel.addCharacterSpacing(kernValue: -1)
            
            for str in strArr {
                tmpLabel.text = str.replacingOccurrences(of: "\n", with: "")
                maximumIntrinsic = max(maximumIntrinsic,tmpLabel.intrinsicContentSize.width)
            }
            print("dkdk")
            print(maximumIntrinsic)
            if maximumIntrinsic > 306 - 38{
                $0.width.equalTo(306)
            }
            else{
                
                $0.width.equalTo(38+maximumIntrinsic)
                
            }
            
            
            
            
            print("maximum")
            print(todoLabel.calculateMaxLines())
            print(todoLabel.frame.height)
            
            
            $0.height.equalTo(27 + 18 + 25 * (todoLabel.calculateMaxLines()-1))
            
        }
        
        
        
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
