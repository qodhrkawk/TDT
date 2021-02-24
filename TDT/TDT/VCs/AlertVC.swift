//
//  AlertVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/23.
//

import UIKit

class AlertVC: UIViewController {
    
    @IBOutlet weak var changeButton: UIButton!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var deleteCheckView: UIView!
    @IBOutlet weak var deleteCancelButton: UIButton!
    
    @IBOutlet weak var deleteCheckLabel: UILabel!
    @IBOutlet weak var deleteOkayButton: UIButton!
    
    
    @IBOutlet weak var editBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var editCancelButton: UIButton!
    @IBOutlet weak var editOkayButton: UIButton!
    @IBOutlet weak var editLineView: UIView!
    @IBOutlet weak var editTextView: UITextView!
    @IBOutlet weak var editLabel: UILabel!
    
    @IBOutlet weak var editUnderView: UIView!

    var myText: String?
    
    var todoDelegate: ToDoDelegate?
    var idx: IndexPath?
    var editOkayImages = ["btnComplete","btnCompleteGr","btnCompleteYl","btnCompletePk"]
    var fromArchive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        setButtons()
        lineView.backgroundColor = UIColor(named: "inactiveColor")
        stackView.makeRounded(cornerRadius: 3)
        setItems()
        
    
        
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        registerForKeyboardNotifications()
        stackView.transform = CGAffineTransform(translationX: 0, y: 200)
        cancelButton.transform = CGAffineTransform(translationX: 0, y: 200)
        UIView.animate(withDuration: 0.15, animations: {
            self.view.backgroundColor = .black60
            self.stackView.transform = .identity
            self.cancelButton.transform = .identity
            
        })
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        unregisterForKeyboardNotifications()
        editTextView.resignFirstResponder()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if editView.alpha == 0{
            UIView.animate(withDuration: 0.15, animations: {
                self.stackView.transform = CGAffineTransform(translationX: 0, y: 200)
                self.cancelButton.transform = CGAffineTransform(translationX: 0, y: 200)
                self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
            },completion: {finished in
                self.todoDelegate?.disMissed(idx: self.idx!)
                self.dismiss(animated: false, completion: nil)
            })
            
        }
     
    }
    
    
    func setItems(){
        deleteCheckView.makeRounded(cornerRadius: 3)
        deleteCheckLabel.font = UIFont(name: "GmarketSansTTFMedium", size: 16)
        deleteCheckLabel.textColor = UIColor(named: "mainTextColor")
        
        deleteCheckView.alpha = 0
        
        editLabel.font = UIFont(name: "GmarketSansTTFMedium", size: 16)
        editTextView.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        editLineView.backgroundColor = UIColor(named: "mainTextColor")
        editLineView.alpha = 0.2
        editView.alpha = 0
        editView.backgroundColor = UIColor(named: "boxColor")
        editTextView.textContainerInset = UIEdgeInsets(top: 17.0,
                                                       left: 25.0,
                                                       bottom: 23.0, right: 25.0)
        editTextView.text = myText
        editTextView.backgroundColor = UIColor(named: "textBoxColor")
        editUnderView.backgroundColor = UIColor(named: "textBoxColor")
        editView.makeRounded(cornerRadius: 3)
        editLabel.textColor = .brownGreyThree
//        editTextView.setLinespace(spacing: 50)
//        editTextView.delegate = self
        if let mainColorIndex = UserDefaults.standard.value(forKey: "mainColor") as? Int {
            TodoVC.mainColor = TodoVC.colors[mainColorIndex]
            let editOkayButtonImageName = editOkayImages[mainColorIndex]
            editOkayButton.setImage(UIImage(named: editOkayButtonImageName), for: .normal)
            
        }
    }
    
    func disableChangeButton(){
       
        
        
        
    }
    
   
    func setButtons(){
        //        cancelButton.makeRounded(cornerRadius: 6)
        
        changeButton.backgroundColor = UIColor(named: "textBoxColor")
        changeButton.titleLabel?.font = UIFont(name: "GmarketSansTTFMedium", size: 16)
        changeButton.setTitleColor(UIColor(named: "mainTextColor"), for: .normal)
        
        
        
        deleteButton.backgroundColor = UIColor(named: "textBoxColor")
        deleteButton.titleLabel?.font = UIFont(name: "GmarketSansTTFMedium", size: 16)
        deleteButton.setTitleColor(UIColor(named: "alertColor"), for: .normal)
        if fromArchive {
            changeButton.setTitleColor(UIColor(named: "inactiveColor"), for: .normal)
        }
        
        
        cancelButton.backgroundColor = UIColor(named: "inactiveColor")
        cancelButton.titleLabel?.font = UIFont(name: "GmarketSansTTFMedium", size: 16)
        cancelButton.setTitleColor(.brownGreyThree, for: .normal)
        cancelButton.makeRounded(cornerRadius: 3)
     
        
        deleteCancelButton.backgroundColor = UIColor(named: "inactiveColor")
        deleteCancelButton.titleLabel?.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        deleteCancelButton.makeRounded(cornerRadius: 3)
        deleteCancelButton.setTitleColor(UIColor(named: "archiveTextColor"), for: .normal)
        
        deleteOkayButton.backgroundColor = UIColor(named: "alertColor")
        deleteOkayButton.titleLabel?.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        deleteOkayButton.setTitleColor(UIColor(named: "mainTextColor"), for: .normal)
        deleteOkayButton.makeRounded(cornerRadius: 3)
        
        
        
        if traitCollection.userInterfaceStyle == .light {
            editCancelButton.setImage(UIImage(named: "btnClose"), for: .normal)
           
        }
        else {
            editCancelButton.setImage(UIImage(named: "dkBtnClose"), for: .normal)
        }
        
        
    }
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)), name:
                                                UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name:
                                                UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unregisterForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name:
                                                    UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name:
                                                    UIResponder.keyboardWillHideNotification, object: nil)
    }
    @objc func keyboardWillShow(_ notification: NSNotification) {
        
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                                as? NSValue)?.cgRectValue {
            
            editBottomConstraint.constant = keyboardSize.height + 75
            self.editView.alpha = 1
            UIView.animate(withDuration: 0.15, animations: {
                self.stackView.transform = CGAffineTransform(translationX: 0, y: 200)
                self.cancelButton.transform = CGAffineTransform(translationX: 0, y: 200)
                
            },completion: {finished in
                self.stackView.alpha = 0
                self.cancelButton.alpha = 0
                
                
            })
            
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        
        
        UIView.animate(withDuration: 1.0, animations: {
            
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                                    as? NSValue)?.cgRectValue {
                
                
                
            }
        })
        
        self.view.layoutIfNeeded()
    }
    
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        
        UIView.animate(withDuration: 0.15, animations: {
            self.stackView.transform = CGAffineTransform(translationX: 0, y: 200)
            self.cancelButton.transform = CGAffineTransform(translationX: 0, y: 200)
            self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
            
        },completion: {finished in
            self.todoDelegate?.disMissed(idx: self.idx!)
            self.dismiss(animated: false, completion: nil)
        })
        
    }
    
    
    @IBAction func deleteButtonAction(_ sender: Any) {
        deleteCheckView.alpha = 1
        stackView.alpha = 0
        cancelButton.alpha = 0
        
    }
    
    @IBAction func changeButtonAction(_ sender: Any) {
        if !fromArchive{
            editTextView.becomeFirstResponder()
        }
       
    }
    
    @IBAction func deleteCancelButtonAction(_ sender: Any) {
        todoDelegate?.disMissed(idx: idx!)
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func deleteOkayButtonAction(_ sender: Any) {
        todoDelegate?.delete(idx: idx!)
        self.dismiss(animated: false, completion: nil)
    }
    
    
    
    @IBAction func editCancelButtonAction(_ sender: Any) {
        todoDelegate?.disMissed(idx: idx!)
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func editOkayButtonAction(_ sender: Any) {
        todoDelegate?.modify(idx: idx!, str: editTextView.text)
       
        self.dismiss(animated: false, completion: nil)
    }
    
}

extension AlertVC: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
//        let mutableAttrStr = NSMutableAttributedString(string: textView.text)
//        let style = NSMutableParagraphStyle()
//        style.lineSpacing = 8
//        mutableAttrStr.addAttributes([NSAttributedString.Key.paragraphStyle:style], range: NSMakeRange(0, mutableAttrStr.length))
//        textView.attributedText = mutableAttrStr
    }
    
}
