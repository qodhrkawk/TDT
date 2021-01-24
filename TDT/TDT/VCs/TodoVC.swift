//
//  TodoVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/21.
//

import UIKit


class TodoVC: UIViewController {
    
    //    var myStr = "왼쪽으로 밀어서 완료 상태로 만들어 보세요.141414141414141414141414141414141414141414141414141414141414141414141414"
    var myStr = "왼쪽으로밀어서완료aaaaaaanaa"
    
    var strs = ["왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요."]

    var isImportant = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]
//    var strs: [String] = []
//
//    var isImportant: [Bool] = []
    var currentStatus = 1
    static var mainColor: UIColor = .greenishCyan
    
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var wholeTV: UITableView!
    
    @IBOutlet weak var wholeTVBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var newTextField: UITextField!
    
    @IBOutlet weak var sendButton: UIButton!
    var nowOffset = CGPoint(x: 0, y: 0)
    var feedbackGenerator: UIImpactFeedbackGenerator?
    override func viewDidLoad() {
        super.viewDidLoad()
        wholeTV.delegate = self
        wholeTV.dataSource = self
        self.view.backgroundColor = .veryLightPinkTwo
        headerView.backgroundColor = .veryLightPinkTwo
        headerView.alpha = 0.95
        setWholeTV()
        setItems()

        self.feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        self.feedbackGenerator?.prepare()
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
       
        currentStatus = 1
        registerForKeyboardNotifications()
    }
    override func viewDidAppear(_ animated: Bool) {
        currentStatus = 0
      
    }
    override func viewWillDisappear(_ animated: Bool) {
        unregisterForKeyboardNotifications()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    func setItems(){
        newTextField.addLeftPadding(left: 7)
        newTextField.addRightPadding(right: 40)
        newTextField.placeholder = "해야 할 일을 입력해주세요."
        newTextField.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        newTextField.delegate = self
        newTextField.addTarget(self, action: #selector(textFieldDidChange(sender:)), for: .editingChanged)
        newTextField.backgroundColor = .veryLightPink30
        
        editView.setBorder(borderColor: .veryLightPinkFour, borderWidth: 1.0)
        
        
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
            
            UIView.animate(withDuration: 0.3, animations: {
                self.editView.transform = CGAffineTransform(translationX: 0, y: -(keyboardSize.height-29))
//                self.wholeTV.transform = CGAffineTransform(translationX: 0, y: -(keyboardSize.height-29))
//                self.wholeTVBottomConstraint.constant = 90 + keyboardSize.height-29
               
                self.nowOffset = self.wholeTV.contentOffset
                print(self.nowOffset)
                self.wholeTV.setContentOffset(CGPoint(x: self.nowOffset.x, y: self.nowOffset.y + keyboardSize.height-29), animated: false)
                self.wholeTV.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height-29, right: 0)
                self.wholeTV.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height-29, right: 0)
                
            })
            
            self.view.layoutIfNeeded()
            
            
            
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        
        
       
            
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                                    as? NSValue)?.cgRectValue {
            
                UIView.animate(withDuration: 0.3, animations: {
                        self.editView.transform = .identity
//                        self.wholeTVBottomConstraint.constant = 90
//                    self.nowOffset = self.wholeTV.contentOffset
                    
                    let goY = self.nowOffset.y > 2 * keyboardSize.height-29 ? self.nowOffset.y - 2*(keyboardSize.height - 29) : 0
                    self.wholeTV.setContentOffset(CGPoint(x: self.nowOffset.x, y: goY), animated: true)

                    
                    self.wholeTV.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                    self.wholeTV.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                    

                       
                    })
                self.view.layoutIfNeeded()
                
            }
       
        
       
    }
    
  
    
    func setWholeTV(){
        wholeTV.isUserInteractionEnabled = true
        wholeTV.backgroundColor = .veryLightPinkTwo
        let tableViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTouched))
        
        wholeTV.addGestureRecognizer(tableViewTapGesture)
        
    }
    
    
    
    @objc func tableViewTouched(){
        self.view.endEditing(true)
    }
    
    @objc func textFieldDidChange(sender:UITextField) {
        
        if let text = sender.text {
            // 초과되는 텍스트 제거
            if text.count >= 1 {
                sendButton.setImage(UIImage(named: "btnSendActive"), for: .normal)
            }
            else{
                sendButton.setImage(UIImage(named: "btnSendInactive"), for: .normal)

            }
            
        }
        
    }
    @IBAction func sendButtonAction(_ sender: Any) {
        if newTextField.text != ""{
            strs.append(newTextField.text!)
            isImportant.append(false)
            newTextField.text = ""
            wholeTV.reloadData()
            currentStatus = 2
        }
        
    }
    
}


extension TodoVC: UITableViewDelegate{
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        
        //                cell.alpha = 0.5
        
        switch currentStatus {
            
        // 뷰 처음 등장할때 오른쪽에서 왼쪽 가는 애니메이션
        case 1:
            cell.alpha = 0.2
            let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, 250, 0, 0)
     
            cell.layer.transform = rotationTransform
            UIView.animate(withDuration: 0.4 ,delay: 0.05 * Double(indexPath.row),options: .curveEaseOut, animations: {
                cell.alpha = 1
                cell.layer.transform = CATransform3DIdentity
            })
            
            
        // 텍스트 추가될때 애니메이션
        case 2:
            let lastIndexPath = IndexPath(row: tableView.numberOfRows(inSection: tableView.numberOfSections - 1) - 1, section: tableView.numberOfSections - 1)

            tableView.scrollToRow(at: lastIndexPath, at: .top, animated: false)
            let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, 0, 250, 0)
            let yMove = CGAffineTransform(translationX: 0, y: 300)

//            cell.layer.transform = rotationTransform
            cell.transform = yMove
            view.bringSubviewToFront(cell)
            if indexPath == lastIndexPath{
                UIView.animate(withDuration: 0.5 ,delay: 0 ,options: .curveEaseOut, animations: {
                    cell.alpha = 1
//                    cell.layer.transform = CATransform3DIdentity
                    cell.transform = .identity
                },completion: { finish in
                    self.currentStatus = 0

                })

            }
        return
            
            
        default:
            return
        
        }
        
       
        
    }
    
    
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
    }
    
}

extension TodoVC: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return strs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodoTVC.identifier) as? TodoTVC else {return UITableViewCell()}
        cell.textBoxDelegate = self
        cell.setLabel(str: strs[indexPath.row])
        cell.myIndexpath = indexPath
        cell.isImportant = isImportant[indexPath.row]
        cell.setItems()

        
        return cell
    }
    
    
    
}

extension TodoVC: TextBoxDelegate {
    func longTapped(idx: IndexPath) {
        feedbackGenerator?.impactOccurred()
        guard let vcName = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(identifier: "AlertVC") as? AlertVC else {return}
        
        vcName.myText = strs[idx.row]
        vcName.idx = idx
        vcName.todoDelegate = self
        vcName.modalPresentationStyle = .overCurrentContext
        
      
        self.present(vcName, animated: false, completion: nil)
    }
    
    func leftSwiped(idx: IndexPath) {
       
            myDeleteRow(idx: idx)
     

    }
    
    func doubleTapped(idx: IndexPath) {
      
        isImportant[idx.row] = !isImportant[idx.row]
        print(isImportant)
        wholeTV.reloadData()
    }
    
    func myDeleteRow(idx: IndexPath){
        wholeTV.beginUpdates()
        self.strs.remove(at: idx.row)
        wholeTV.deleteRows(at: [idx], with: .fade)
        wholeTV.endUpdates()
        
        print("숫자")
        
        print(wholeTV.numberOfRows(inSection: 0))
        for sec in idx.section...wholeTV.numberOfSections-1{
            if sec == idx.section{
                if wholeTV.numberOfRows(inSection: sec) > idx.row {
                    for row in idx.row...wholeTV.numberOfRows(inSection: sec)-1{
                        guard let cell = wholeTV.cellForRow(at: IndexPath(row: row, section: sec)) as? TodoTVC else { continue}
                        cell.myIndexpath = IndexPath(row: row, section: sec)
                    }
                }
                
                
            }
            else{
                if wholeTV.numberOfRows(inSection: sec) > 0 {
                    for row in 0...wholeTV.numberOfRows(inSection: sec)-1{
                        guard let cell = wholeTV.cellForRow(at: IndexPath(row: row, section: sec)) as? TodoTVC else { continue}
                        cell.myIndexpath = IndexPath(row: row, section: sec)
                    }
                }
            }
            
        }
        
    }
    
}


extension TodoVC: UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        
    }
    
}

extension TodoVC: ToDoDelegate{
    func delete(idx: IndexPath){
        myDeleteRow(idx: idx)
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: idx.row, section: idx.section)) as? TodoTVC else { return}
       
        cell.wasLongTapped = false
        self.showToast(text: "삭제되었어요.",withDelay: 0.6)
    }
    func modify(idx: IndexPath,str: String){
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: idx.row, section: idx.section)) as? TodoTVC else { return}
       
        cell.wasLongTapped = false
        strs[idx.row] = str
        wholeTV.reloadData()
        self.showToast(text: "수정되었어요",withDelay: 0.3)
    }
    
    func disMissed(idx: IndexPath) {
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: idx.row, section: idx.section)) as? TodoTVC else { return}
        print("왜?")
        cell.wasLongTapped = false
    }
    
}


extension TodoVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        nowOffset = scrollView.contentOffset
        print(self.nowOffset)
    }
    
}
