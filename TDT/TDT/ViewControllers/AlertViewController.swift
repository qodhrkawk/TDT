//
//  AlertViewController.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/23.
//

import UIKit

class AlertViewController: UIViewController {
    
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

    var contentText: String?
    var indexPath: IndexPath?
    
    weak var todoDelegate: ToDoDelegate?
    
    var fromArchive = false
    
    private var mainColor: UIColor {
        guard let currentTheme = ThemeManager.shared.currentTheme else { return Theme.blue.mainColor }
        return currentTheme.mainColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)

        stackView.makeRounded(cornerRadius: 8)
        setupUIs()
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
            },completion: { [weak self] _ in
                guard let self, let indexPath = self.indexPath else { return }
                self.todoDelegate?.dismissed(indexPath: indexPath)
                self.dismiss(animated: false, completion: nil)
            })
        }
    }
    
    func setupUIs(){
        lineView.backgroundColor = Design.Color.inactiveColor
        
        deleteCheckView.makeRounded(cornerRadius: 8)
        deleteCheckLabel.font = Design.Font.deleteCheckLabelFont
        deleteCheckLabel.textColor = Design.Color.mainTextColor
        
        deleteCheckView.alpha = 0
        
        editLabel.font = Design.Font.editLabelFont
        editTextView.font = Design.Font.editTextViewFont
        editLineView.backgroundColor = Design.Color.editLineColor
        editLineView.alpha = 0.2
        editView.alpha = 0
        editView.backgroundColor = Design.Color.editViewBackgroundColor
        editTextView.textContainerInset = UIEdgeInsets(top: 17.0,
                                                       left: 25.0,
                                                       bottom: 23.0, right: 25.0)
        editTextView.text = contentText
        editTextView.backgroundColor = Design.Color.editTextViewBackgroundColor
        editUnderView.backgroundColor = Design.Color.editTextViewBackgroundColor
        editView.makeRounded(cornerRadius: 8)
        editLabel.textColor = .brownGreyThree
        
        if let currentTheme = ThemeManager.shared.currentTheme {
            editOkayButton.setImage(currentTheme.editOkayButtonImage, for: .normal)
        }
        
        setupButtons()
    }

    func setupButtons(){
        changeButton.backgroundColor = Design.Color.boxColor
        changeButton.titleLabel?.font = Design.Font.buttonFont
        changeButton.setTitleColor(Design.Color.mainTextColor, for: .normal)
        
        deleteButton.backgroundColor = Design.Color.boxColor
        deleteButton.titleLabel?.font = Design.Font.buttonFont
        deleteButton.setTitleColor(mainColor, for: .normal)

        if fromArchive {
            changeButton.setTitleColor(Design.Color.inactiveColor, for: .normal)
        }
        
        cancelButton.backgroundColor = Design.Color.boxColor
        cancelButton.titleLabel?.font = Design.Font.buttonFont
        cancelButton.setTitleColor(Design.Color.mainTextColor, for: .normal)
        cancelButton.makeRounded(cornerRadius: 8)
     
        deleteCancelButton.backgroundColor = Design.Color.inactiveColor
        deleteCancelButton.titleLabel?.font = Design.Font.deleteCheckButtonFont
        deleteCancelButton.makeRounded(cornerRadius: 8)
        deleteCancelButton.setTitleColor(Design.Color.deleteCancelButtonColor, for: .normal)
        
        deleteOkayButton.backgroundColor = Design.Color.deleteOkayButtonColor
        deleteOkayButton.titleLabel?.font = Design.Font.deleteCheckButtonFont
        deleteOkayButton.setTitleColor(Design.Color.mainTextColor, for: .normal)
        deleteOkayButton.makeRounded(cornerRadius: 8)
        
        if traitCollection.userInterfaceStyle == .light {
            editCancelButton.setImage(Design.Image.editCancelButtonImage, for: .normal)
           
        }
        else {
            editCancelButton.setImage(Design.Image.editCancelButtonDarkImage, for: .normal)
        }
    }
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }
    
    func unregisterForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardSize =
            (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            editBottomConstraint.constant = keyboardSize.height + 75
            
            self.editView.alpha = 1
            UIView.animate(
                withDuration: 0.15,
                animations: {
                    self.stackView.transform = CGAffineTransform(translationX: 0, y: 200)
                    self.cancelButton.transform = CGAffineTransform(translationX: 0, y: 200)
                },
                completion: { [weak self] _ in
                    self?.stackView.alpha = 0
                    self?.cancelButton.alpha = 0
                })
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        self.view.layoutIfNeeded()
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        UIView.animate(
            withDuration: 0.15,
            animations: {
            self.stackView.transform = CGAffineTransform(translationX: 0, y: 200)
            self.cancelButton.transform = CGAffineTransform(translationX: 0, y: 200)
                self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
            },
            completion: { [weak self] _ in
                guard let self, let indexpath = self.indexPath else { return }
                
                self.todoDelegate?.dismissed(indexPath: indexpath)
                self.dismiss(animated: false, completion: nil)
            })
    }
    
    
    @IBAction func deleteButtonAction(_ sender: Any) {
        deleteCheckView.alpha = 1
        stackView.alpha = 0
        cancelButton.alpha = 0
    }
    
    @IBAction func changeButtonAction(_ sender: Any) {
        if !fromArchive {
            editTextView.becomeFirstResponder()
        }
    }
    
    @IBAction func deleteCancelButtonAction(_ sender: Any) {
        guard let indexPath else { return }
        
        todoDelegate?.dismissed(indexPath: indexPath)
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func deleteOkayButtonAction(_ sender: Any) {
        guard let indexPath else { return }
        
        todoDelegate?.delete(indexPath: indexPath)
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func editCancelButtonAction(_ sender: Any) {
        guard let indexPath else { return }
        
        todoDelegate?.dismissed(indexPath: indexPath)
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func editOkayButtonAction(_ sender: Any) {
        guard let indexPath else { return }
        
        todoDelegate?.modify(indexPath: indexPath, str: editTextView.text)
       
        dismiss(animated: false, completion: nil)
    }
}

enum Design {
    enum Color {
        static let boxColor = UIColor(named: "boxColor")
        static let mainTextColor = UIColor(named: "mainText")
        static let editLineColor = UIColor(named: "typingTextColor")?.withAlphaComponent(0.16)
        static let editViewBackgroundColor = UIColor(named: "boxColor")
        static let editTextViewBackgroundColor = UIColor(named: "textBoxColor")
        
        static let changeButtonColor = UIColor(named: "textBoxColor")
        static let deleteButtonColor = UIColor(named: "textBoxColor")
        
        static let inactiveColor = UIColor(named: "inactiveColor")
        static let deleteCancelButtonColor = UIColor(named: "archiveTextColor")
        static let deleteOkayButtonColor = UIColor(named: "alertColor")
    }
    
    enum Image {
        static let editCancelButtonImage = UIImage(named: "btnClose")
        static let editCancelButtonDarkImage = UIImage(named: "dkBtnClose")
    }
    
    enum Font {
        static let deleteCheckLabelFont = UIFont(name: "GmarketSansTTFMedium", size: 16)
        static let editLabelFont = UIFont(name: "GmarketSansTTFMedium", size: 16)
        static let editTextViewFont = UIFont(name: "GmarketSansTTFMedium", size: 15)
        
        static let buttonFont =  UIFont(name: "GmarketSansTTFMedium", size: 16)
        static let deleteCheckButtonFont = UIFont(name: "GmarketSansTTFMedium", size: 15)
    }
}
