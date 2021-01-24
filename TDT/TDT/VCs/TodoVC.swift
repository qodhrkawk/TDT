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
    let defaults = UserDefaults.standard
//    var strs = ["왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요."]
//
//    var isImportant = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]
    //    var strs: [String] = []
    //
    //    var isImportant: [Bool] = []
    
    var wholeData: WholeData?
    var dateInfo: [String] = []
    
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
    
    var controlDelegate: ControlDelegate?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setData()
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
        print("todoviewwillapp")
        currentStatus = 1
        
        wholeTV.reloadData()
        registerForKeyboardNotifications()
    }
    override func viewDidAppear(_ animated: Bool) {
        print("todoviewdidapp")
        
        
        currentStatus = 0
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        print("todoviewwilldisapp")
        unregisterForKeyboardNotifications()
        
        currentStatus = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func setData(){
        
        if let wholeData = defaults.value(forKey: "wholeData") as? Data{
            let originalData = try? PropertyListDecoder().decode(Dictionary<Int,[TodoData]>.self, from: wholeData)
     
            
            if originalData != nil{
           
                self.wholeData = WholeData(dict: originalData!)
            }
            
        }
        else {
            
            let emptyDict: Dictionary<Int,[TodoData]> = [:]
            defaults.setValue(emptyDict, forKey: "wholeData")
            self.wholeData = WholeData(dict: emptyDict)
        }
       
        
        
        wholeTV.reloadData()
        print(self.wholeData)
        
        if wholeData!.dict.count > 0 {
            for i in 0...wholeData!.dict.count-1 {
                let dateIdx = "date"+String(i)
                if let tmpDate = defaults.string(forKey: dateIdx) {
                    dateInfo.append(tmpDate)
                }
            }
            print(dateInfo)
            
        }
       
        
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
    
    
    func addData(todo: String){
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
            let date = Date()
            let dateString = dateFormatter.string(from: date)


            if wholeData!.dict.count > 0  {
                let dateKey = "date"+String(wholeData!.dict.count-1)
                print(dateKey)
                if let myDate = defaults.string(forKey: dateKey) {
                    
                   
                    if myDate == dateString{
                        print("heeeeeee")
                        wholeData!.dict[wholeData!.dict.count-1]?.append(TodoData(date: dateString, todo: todo, isImportant: false))
                    }
                    else{
                        let dateKey = "date"+String(wholeData!.dict.count)
                        defaults.setValue(dateString, forKey: dateKey)
                        dateInfo.append(dateString)
                        wholeData!.dict[wholeData!.dict.count] = [TodoData(date: dateString, todo: todo, isImportant: false)]
                    }
                    
                    
                    
                    
                }

            }
            else{
                let dateKey = "date"+String(wholeData!.dict.count)
                defaults.setValue(dateString, forKey: dateKey)
                
                wholeData!.dict[0] = [TodoData(date: dateString, todo: todo, isImportant: false)]
                dateInfo.append(dateString)
               


            }
        
        
        defaults.set(try? PropertyListEncoder().encode(wholeData!.dict), forKey: "wholeData")
    
        wholeTV.reloadData()
        
        
    }
    
    func setWholeTV(){
        wholeTV.isUserInteractionEnabled = true
        wholeTV.backgroundColor = .veryLightPinkTwo
        let tableViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTouched))
        
        wholeTV.addGestureRecognizer(tableViewTapGesture)
        
    }
    
    
    
    @IBAction func archiveButtonAction(_ sender: Any) {
        controlDelegate?.moveTo(idx: 0)
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
            addData(todo: newTextField.text!)
            newTextField.text = ""
            
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
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        switch section {
          case 0:
              let view = FirstHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 65))
              view.setDate(date: dateInfo[section])
              return view
          default:
              let view = FirstHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
                
              view.setDate(date: dateInfo[section])
              return view
          }
        
        
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
          case 0:
             return 65
          default:
              return 30
          }
    }
  
    
}

extension TodoVC: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wholeData!.dict[section]!.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return wholeData!.dict.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodoTVC.identifier) as? TodoTVC else {return UITableViewCell()}
        cell.textBoxDelegate = self
        cell.setLabel(str: wholeData!.dict[indexPath.section]![indexPath.row].todo)
        cell.myIndexpath = indexPath
        cell.isImportant = wholeData!.dict[indexPath.section]![indexPath.row].isImportant
        cell.setItems()
        
        
        return cell
    }
    
   
    
    
}

extension TodoVC: TextBoxDelegate {
    func longTapped(idx: IndexPath) {
        feedbackGenerator?.impactOccurred()
        guard let vcName = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(identifier: "AlertVC") as? AlertVC else {return}
        
        vcName.myText = wholeData!.dict[idx.section]![idx.row].todo
        vcName.idx = idx
        vcName.todoDelegate = self
        vcName.modalPresentationStyle = .overCurrentContext
        
        
        self.present(vcName, animated: false, completion: nil)
    }
    
    func leftSwiped(idx: IndexPath) {
        
        myDeleteRow(idx: idx,isEnd: true)
        
        
    }
    func shouldMove() {
        controlDelegate?.moveTo(idx: 0)
    }
    
    func doubleTapped(idx: IndexPath) {
        
        wholeData!.dict[idx.section]![idx.row].isImportant = !wholeData!.dict[idx.section]![idx.row].isImportant
        wholeTV.reloadData()
    }
    
    func myDeleteRow(idx: IndexPath,isEnd: Bool){
        wholeTV.beginUpdates()
        self.wholeData!.dict[idx.section]!.remove(at: idx.row)
        
        
        // 삭제 (날짜 + 데이터)
        if wholeData!.dict[idx.section]!.count == 0{
            
        }
        
        defaults.set(try? PropertyListEncoder().encode(wholeData!.dict), forKey: "wholeData")
        
        
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
        myDeleteRow(idx: idx,isEnd: false)
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: idx.row, section: idx.section)) as? TodoTVC else { return}
        
        cell.wasLongTapped = false
        self.showToast(text: "삭제되었어요.",withDelay: 0.6)
    }
    func modify(idx: IndexPath,str: String){
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: idx.row, section: idx.section)) as? TodoTVC else { return}
        
        cell.wasLongTapped = false
        wholeData!.dict[idx.section]![idx.row].todo = str
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
