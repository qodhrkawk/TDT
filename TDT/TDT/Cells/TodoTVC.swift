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
    
    @IBOutlet weak var todoLabel: UILabel!
    var todo: String?
    
  
    
    override func awakeFromNib() {
        super.awakeFromNib()
        todoLabel.setLinespace(spacing: 8)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setLabel(str: String){
        todoLabel.text = str
        let viewWidth = todoLabel.intrinsicContentSize.width
        
        print(viewWidth)
        print(todoLabel.intrinsicContentSize.height)
        
        
        
                
        
        
        
        containView.snp.remakeConstraints{
            $0.leading.equalTo(todoLabel.snp.leading).offset(-19)
            $0.top.equalTo(todoLabel.snp.top).offset(-16)
//            $0.trailing.equalTo(todoLabel.snp.trailing).offset(19)
//            $0.bottom.equalTo(todoLabel.snp.bottom).offset(16)
            
            if todoLabel.calculateMaxLines() > 1 {
                var maximumIntrinsic = CGFloat(0.0)

                print(getLinesArrayFromLabel(label: todoLabel))
                var strArr = getLinesArrayFromLabel(label: todoLabel)
                var tmpLabel = UILabel()
                
                for str in strArr {
                    tmpLabel.text = str
                    maximumIntrinsic = max(maximumIntrinsic,tmpLabel.intrinsicContentSize.width)
                }
                print("dkdk")
                print(maximumIntrinsic)
                if maximumIntrinsic > 306{
                    $0.width.equalTo(306)
                }
                else{
                    $0.width.equalTo(38+maximumIntrinsic)
                    
                }
               
            }
    
            else{
                $0.width.equalTo(38+viewWidth)
            }
            
            $0.height.equalTo(33 + 18 * todoLabel.calculateMaxLines())

        }
        
        
        
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
