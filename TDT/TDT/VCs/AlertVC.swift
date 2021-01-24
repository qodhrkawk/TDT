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
    
    var fromArchive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        setButtons()
        lineView.backgroundColor = .veryLightPinkThree
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
        
        
        deleteCheckView.alpha = 0
        
        editLabel.font = UIFont(name: "GmarketSansTTFMedium", size: 16)
        editTextView.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        editLineView.backgroundColor = .veryLightPinkTwo
        editView.alpha = 0
        editTextView.textContainerInset = UIEdgeInsets(top: 17.0,
                                                       left: 25.0,
                                                       bottom: 23.0, right: 25.0)
        editTextView.text = myText
        editTextView.backgroundColor = .white1
        editUnderView.backgroundColor = .white1
        editView.makeRounded(cornerRadius: 3)
        editLabel.textColor = .brownGreyThree
//        editTextView.setLinespace(spacing: 50)
//        editTextView.delegate = self
    }
    
    func disableChangeButton(){
       
        
        
        
    }
    
    func setButtons(){
        //        cancelButton.makeRounded(cornerRadius: 6)
        
        changeButton.backgroundColor = .subgrey
        changeButton.titleLabel?.font = UIFont(name: "GmarketSansTTFMedium", size: 16)
        changeButton.setTitleColor(.black, for: .normal)
        
        
        
        deleteButton.backgroundColor = .subgrey
        deleteButton.titleLabel?.font = UIFont(name: "GmarketSansTTFMedium", size: 16)
        deleteButton.setTitleColor(.warmPink, for: .normal)
        if fromArchive {
            changeButton.setTitleColor(.brownGreyFour, for: .normal)
        }
        
        
        cancelButton.backgroundColor = .subgrey
        cancelButton.titleLabel?.font = UIFont(name: "GmarketSansTTFMedium", size: 16)
        cancelButton.setTitleColor(.brownGreyThree, for: .normal)
        cancelButton.makeRounded(cornerRadius: 3)
     
        
        deleteCancelButton.backgroundColor = .veryLightPinkTwo
        deleteCancelButton.titleLabel?.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        deleteCancelButton.makeRounded(cornerRadius: 3)
        
        deleteOkayButton.backgroundColor = .warmPink
        deleteOkayButton.titleLabel?.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        deleteOkayButton.setTitleColor(.white, for: .normal)
        deleteOkayButton.makeRounded(cornerRadius: 3)
        
        
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
