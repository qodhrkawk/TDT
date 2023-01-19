//
//  TodoVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/21.
//

import UIKit


class TodoVC: UIViewController {
    
    private let userDefaults = UserDefaults.standard

    var dateInfo: [String] = []
    
    var todoDatas: [[TodoData]] = []

    var delaySection = -1
    
    var currentStatus = 1
    static var mainColor: UIColor = .maincolor
    static var colors = [UIColor.maincolor,UIColor.shamrockGreen,UIColor.sunYellow,UIColor.warmPink]
    var flickImages = ["imgLogo","imgLogoGr","imgLogoYl","imgLogoPk"]
    var darkFlickImages = ["dkImgLogo","dkImgLogoGr","dkImgLogoYl","dkImgLogoPk"]
    var sendButtonImages = ["btnSendActive","btnSendActiveGr","btnSendActiveYl","btnSendActivePk"]
    
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var wholeTV: UITableView!
    @IBOutlet weak var flickImage: UIImageView!
    @IBOutlet weak var archiveButton: UIButton!
    
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var wholeTVBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var newTextField: UITextField!
    var pastKeyboardSize = CGRect(x: 0, y: 0, width: 0, height: 0)
    @IBOutlet weak var sendButton: UIButton!
    var nowOffset = CGPoint(x: 0, y: 0)
    var feedbackGenerator: UIImpactFeedbackGenerator?
    var keyboardFlag = false
    var controlDelegate: ControlDelegate?
    var rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwiped))
    var emptyView = EmptyView(type: .main)
    var sendButtonEnableImage: UIImage?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        initialThreeBoxes()
        setData()
        wholeTV.delegate = self
        wholeTV.dataSource = self
        self.view.backgroundColor = UIColor(named: "bgColor")
        headerView.backgroundColor = UIColor(named: "bgColor")
        headerView.alpha = 0.95
        setWholeTV()
        setItems()
        editView.backgroundColor = UIColor(named: "boxColor")
        setMainColor()
        
        
        
        self.feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        self.feedbackGenerator?.prepare()
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        print("todoviewwillapp")
        registerKeyboardSizeChangedNotification()
        currentStatus = 1
        setData()
        setMainColor()
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
        unregisterKeyboardSizeChangedNotification()
        currentStatus = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func setMainColor(){
        if let mainColorIndex = userDefaults.value(forKey: "mainColor") as? Int {
            TodoVC.mainColor = TodoVC.colors[mainColorIndex]
            var flickImageName = flickImages[mainColorIndex]
            let sendButtonImageName = sendButtonImages[mainColorIndex]
            
            
            if traitCollection.userInterfaceStyle == .dark {
                flickImageName = darkFlickImages[mainColorIndex]
            }
            flickImage.image = UIImage(named: flickImageName)
            sendButtonEnableImage = UIImage(named: sendButtonImageName)
        }
        
        
        
    }
    
    func setData(){
        if let savedData = userDefaults.value(forKey: "TodoDatas") as? Data{
            let originalData = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData)
            
            
            if originalData != nil{
                
                self.todoDatas = originalData!
            }
            
        }
        
        
        if todoDatas.count > 0 {
            
            if let tmpDate = userDefaults.stringArray(forKey: "dates") {
                dateInfo = tmpDate
            }
            
            print(dateInfo)
            
        }
        wholeTV.reloadData()
        
   
        
    }
    
    func initialThreeBoxes(){
        if let data = userDefaults.string(forKey: "initiated") {
            return
        }
        else{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy.MM.dd"
            let date = Date()
            let dateString = dateFormatter.string(from: date)
            todoDatas.append([TodoData(date: dateString, todo: "왼쪽으로 밀어서 완료 상태로 만들어 보세요.", isImportant: false),
                              TodoData(date: dateString, todo: "두번 탭해서 중요 표시를 해 보세요.", isImportant: false),
                              TodoData(date: dateString, todo: "길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.", isImportant: false)])
          
            dateInfo.append(dateString)
            
            userDefaults.setValue(dateInfo, forKey: "dates")
            
            userDefaults.set(try? PropertyListEncoder().encode(todoDatas),forKey: "TodoDatas")
            userDefaults.setValue("yes", forKey: "initiated")
        }
        
    }
    
    
    func setItems(){
        newTextField.addLeftPadding(left: 7)
        newTextField.addRightPadding(right: 40)
        newTextField.placeholder = "해야 할 일을 입력해주세요."
        newTextField.font = UIFont(name: "GmarketSansTTFMedium", size: 15)
        newTextField.delegate = self
        newTextField.addTarget(self, action: #selector(textFieldDidChange(sender:)), for: .editingChanged)
        newTextField.backgroundColor = UIColor(named: "textBoxColor")
        newTextField.textColor = UIColor(named: "typingTextColor")
        
        editView.setBorder(borderColor: UIColor(named: "boxColor"), borderWidth: 1.0)
        rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwiped))
        self.view.isUserInteractionEnabled = true
        rightSwipe.direction = .right
        self.view.addGestureRecognizer(rightSwipe)
        
        if traitCollection.userInterfaceStyle == .light {
            archiveButton.setImage(UIImage(named: "btnArchive"), for: .normal)
            sendButton.setImage(UIImage(named: "btnSendInactive"), for: .normal)
            moreButton.setImage(UIImage(named: "btnMore"), for: .normal)
            
        }
        else {
            archiveButton.setImage(UIImage(named: "dkBtnArchive"), for: .normal)
            sendButton.setImage(UIImage(named: "dkBtnSendInactive"), for: .normal)
            moreButton.setImage(UIImage(named: "dkBtnMore"), for: .normal)
        }
       
        
    }
    
    func registerForKeyboardNotifications() {
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(keyboardWillShow(_:)), name:
//                                                UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name:
                                                UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unregisterForKeyboardNotifications() {
//        NotificationCenter.default.removeObserver(self, name:
//                                                    UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name:
                                                    UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func registerKeyboardSizeChangedNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardSizeChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
    }
    func unregisterKeyboardSizeChangedNotification(){
        NotificationCenter.default.removeObserver(self, name:
                                                    UIResponder.keyboardDidChangeFrameNotification, object: nil)
        
    }
    
    @objc func keyboardSizeChanged(_ notification: NSNotification) {
        self.view.bringSubviewToFront(editView)
        
        keyboardFlag = false
        if keyboardFlag == false {
            keyboardFlag = true

            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                                    as? NSValue)?.cgRectValue {
                print("zzzz")
                print(keyboardSize.height)
                if keyboardSize.height == pastKeyboardSize.height {
                    print("리턴")
                    return
                }
                pastKeyboardSize = keyboardSize
                
                print(keyboardSize.height)
                UIView.animate(withDuration: 0.3, animations: {
                    self.editView.transform = CGAffineTransform(translationX: 0, y: -(keyboardSize.height-29))
 
                    self.nowOffset = self.wholeTV.contentOffset
                    print(self.nowOffset)
                    self.wholeTV.setContentOffset(CGPoint(x: self.nowOffset.x, y: self.nowOffset.y + keyboardSize.height-29), animated: false)
                    self.wholeTV.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height-29, right: 0)
                    self.wholeTV.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height-29, right: 0)
                    
                })
                
                self.view.layoutIfNeeded()
                
                
                
            }
            
            
        }
        
     
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        self.view.bringSubviewToFront(editView)
        if keyboardFlag == false {
            keyboardFlag = true
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                                    as? NSValue)?.cgRectValue {
                
                print(keyboardSize.height)
                UIView.animate(withDuration: 0.3, animations: {
                    self.editView.transform = CGAffineTransform(translationX: 0, y: -(keyboardSize.height-29))
 
                    self.nowOffset = self.wholeTV.contentOffset
                    print(self.nowOffset)
                    self.wholeTV.setContentOffset(CGPoint(x: self.nowOffset.x, y: self.nowOffset.y + keyboardSize.height-29), animated: false)
                    self.wholeTV.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height-29, right: 0)
                    self.wholeTV.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height-29, right: 0)
                    
                })
                
                self.view.layoutIfNeeded()
                
                
                
            }
            
            
        }
        
     
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        
        
        print("키보드 숨김")
        if keyboardFlag == true {
            keyboardFlag = false
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                                    as? NSValue)?.cgRectValue {
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.editView.transform = .identity

                    
                    let goY = self.nowOffset.y > keyboardSize.height-29 ? self.nowOffset.y - (keyboardSize.height - 29) : 0

                    self.wholeTV.contentInset = UIEdgeInsets(top: keyboardSize.height-29, left: 0, bottom: 0, right: 0)
                    self.wholeTV.setContentOffset(CGPoint(x: self.nowOffset.x, y: goY), animated: true)
                    self.wholeTV.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                    
                    
                    
                })
                self.view.layoutIfNeeded()
                pastKeyboardSize = CGRect(x: 0, y: 0, width: 0, height: 0)
                self.wholeTV.contentInset = UIEdgeInsets(top:0, left: 0, bottom: 0, right: 0)
            }
            
            
        }
       
        
        
    }
    @objc func rightSwiped() {
    
        controlDelegate?.moveTo(idx: 0)
    }
    
    
    func addData(todo: String){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        
        // 기존 데이터가 1개 이상
        if todoDatas.count > 0 {
            if let myDate = userDefaults.stringArray(forKey: "dates") {
                
                // 마지막이 같은 날짜이면
                if dateInfo[todoDatas.count-1] == dateString {
                    print("heeeeeee")
//                    wholeData!.dict[wholeData!.dict.count-1]?.append(TodoData(date: dateString, todo: todo, isImportant: false))
                    todoDatas[todoDatas.count-1].append(TodoData(date: dateString, todo: todo, isImportant: false))
                    
                }
                // 날짜 추가
                else{
                    var tmpDate = myDate
                    tmpDate.append(dateString)
                    userDefaults.setValue(tmpDate, forKey: "dates")
                    dateInfo.append(dateString)
//                    wholeData!.dict[wholeData!.dict.count] = [TodoData(date: dateString, todo: todo, isImportant: false)]
                    todoDatas.append([TodoData(date: dateString, todo: todo, isImportant: false)])
                }

            }
            
            
        }
        else{
            let newDate = [dateString]
            
            userDefaults.setValue(newDate, forKey: "dates")
            
//            wholeData!.dict[0] = [TodoData(date: dateString, todo: todo, isImportant: false)]
            todoDatas.append([TodoData(date: dateString, todo: todo, isImportant: false)])
            
            dateInfo.append(dateString)
            
            
            
        }
        
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas),forKey: "TodoDatas")
//        defaults.set(try? PropertyListEncoder().encode(wholeData!.dict), forKey: "wholeData")
        
        wholeTV.reloadData()

        
    }
    
    func setWholeTV(){
        wholeTV.isUserInteractionEnabled = true
        wholeTV.backgroundColor = UIColor(named: "bgColor")
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
                sendButton.setImage(sendButtonEnableImage, for: .normal)
            }
            else{
                
                if traitCollection.userInterfaceStyle == .light {
                    sendButton.setImage(UIImage(named: "btnSendInactive"), for: .normal)
                }
                else {
                    sendButton.setImage(UIImage(named: "dkBtnSendInactive"), for: .normal)
                }
                
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
    
    
    @IBAction func settingButtonAction(_ sender: Any) {
        guard let settingViewController = UIStoryboard(
            name: "Setting",
            bundle: nil
        ).instantiateViewController(
            identifier: "SettingViewController"
        ) as? SettingViewController else { return }

        settingViewController.modalPresentationStyle = .fullScreen
        self.present(settingViewController, animated: true, completion: nil)
    }
    
}


extension TodoVC: UITableViewDelegate{
    
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        switch currentStatus {
        
        // 뷰 처음 등장할때 오른쪽에서 왼쪽 가는 애니메이션
        case 1:
            view.alpha = 0.2
            let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, 250, 0, 0)
            if delaySection == -1 {
                delaySection = section
            }
            
            view.layer.transform = rotationTransform
            let delay = 0.1 + 0.05 * Double(abs(section-delaySection))
            
            UIView.animate(withDuration: 0.4 ,delay: delay,options: .curveEaseOut, animations: {
                view.alpha = 1
                view.layer.transform = CATransform3DIdentity
            },completion: { f in
                self.delaySection = -1
            })
            
            
            
            
        default:
            return
            
        }
        
        
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        

        switch currentStatus {
        
        
        // 뷰 처음 등장할때 오른쪽에서 왼쪽 가는 애니메이션
        case 1:
            cell.alpha = 0.2
            
            
            let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, 250, 0, 0)
            if delaySection == -1 {
                delaySection = indexPath.section
            }
            
            let delay = 0.1 + 0.05 * Double(abs(indexPath.section-delaySection)) + 0.02 * Double(indexPath.row)
            cell.layer.transform = rotationTransform
            UIView.animate(withDuration: 0.4 ,delay: delay,options: .curveEaseOut, animations: {
                cell.alpha = 1
                cell.layer.transform = CATransform3DIdentity
            },completion: { f in
                self.delaySection = -1
            })
            
            
        // 텍스트 추가될때 애니메이션
        case 2:
            let lastIndexPath = IndexPath(row: tableView.numberOfRows(inSection: tableView.numberOfSections - 1) - 1, section: tableView.numberOfSections - 1)
            
            tableView.scrollToRow(at: lastIndexPath, at: .top, animated: false)
            let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, 0, 250, 0)
            let yMove = CGAffineTransform(translationX: 0, y: 300)

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
//        let index =  wholeData!.dict.index( wholeData!.dict.startIndex, offsetBy: section)
//        guard let keys = wholeData!.dict[wholeData!.dict.keys[index]] as? [TodoData] else {return 0}
//        print("난희?")
//
        if section == todoDatas.count-1 {
            var widgetArr:[String] = []
            for data in todoDatas[section] {
                widgetArr.append(data.todo)
            }
            
            userDefaults.setValue(widgetArr, forKey: "widget")
        }
        
        return todoDatas[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if todoDatas.count == 0 {
            self.view.addSubview(emptyView)
            
            self.emptyView.snp.makeConstraints{
                $0.center.equalToSuperview()
                $0.width.equalToSuperview()
                $0.height.equalTo(62)
            }
        }
        else {
            
            emptyView.removeFromSuperview()
            
        }
        
        return todoDatas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodoTVC.identifier) as? TodoTVC else {return UITableViewCell()}

        cell.textBoxDelegate = self
        cell.setLabel(str: todoDatas[indexPath.section][indexPath.row].todo)
        cell.myIndexpath = indexPath
        cell.isImportant = todoDatas[indexPath.section][indexPath.row].isImportant
        cell.setItems()
        
        
        return cell
    }
    
    
    
    
}

extension TodoVC: TextBoxDelegate {
    func longTapped(idx: IndexPath) {
        feedbackGenerator?.impactOccurred()
        guard let vcName = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(identifier: "AlertVC") as? AlertVC else {return}
        self.view.endEditing(true)
        vcName.myText = todoDatas[idx.section][idx.row].todo
        
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
        todoDatas[idx.section][idx.row].isImportant = !todoDatas[idx.section][idx.row].isImportant
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas), forKey: "TodoDatas")
        wholeTV.reloadData()
    }
    
    func myDeleteRow(idx: IndexPath,isEnd: Bool){

        wholeTV.beginUpdates()
        
        if isEnd {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy.MM.dd"
            let date = Date()
            let dateString = dateFormatter.string(from: date)
            if let savedData = userDefaults.value(forKey: "ArchiveDatas") as? Data{
                let originalData = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData)
                
                var archiveTmpData = originalData
                
                if let archiveDate = userDefaults.stringArray(forKey: "ArchiveDates") {
                    var archiveTmpDate = archiveDate
                    if archiveDate.count > 0 {
                        var flag = false
                        for i in 0...archiveDate.count-1 {
                            
                            // 원래 있던 날짜
                            if dateString == archiveDate[i] {
                                flag = true
                                archiveTmpData![i].append(todoDatas[idx.section][idx.row])
                            }
                        }
                        
                        // 날짜 추가해야함
                        if !flag {
                            archiveTmpData!.insert([todoDatas[idx.section][idx.row]], at: 0)
                            archiveTmpDate.insert(dateString, at: 0)

                        }
                        
                    }
                    else {
                        archiveTmpData = [[todoDatas[idx.section][idx.row]]]
                        archiveTmpDate = [dateString]
                        
                        userDefaults.setValue([dateString], forKey: "ArchiveDates")
                        
                    }
                    userDefaults.setValue(archiveTmpDate, forKey: "ArchiveDates")
                    
                }
                
                userDefaults.set(try? PropertyListEncoder().encode(archiveTmpData),forKey: "ArchiveDatas")
                
            }
            // 기존에 archive data 없음
            else {
                userDefaults.set(try? PropertyListEncoder().encode([[todoDatas[idx.section][idx.row]]]),forKey: "ArchiveDatas")
                userDefaults.setValue([dateString], forKey: "ArchiveDates")
            }

        }
        
        todoDatas[idx.section].remove(at: idx.row)
     
        // 삭제 (날짜 + 데이터)
        if todoDatas[idx.section].count == 0{
            //            wholeData!.dict.removeValue(forKey: wholeData!.dict.keys[index])
            todoDatas.remove(at: idx.section)
        }
        
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas), forKey: "TodoDatas")
        
        if wholeTV.numberOfRows(inSection: idx.section) == 1 {
            dateInfo.remove(at: idx.section)
            userDefaults.setValue(dateInfo, forKey: "dates")
            wholeTV.deleteSections([idx.section], with: .fade)
        }
        else{
            wholeTV.deleteRows(at: [idx], with: .fade)
        }
        
        wholeTV.endUpdates()
        wholeTV.reloadData()
    }
    
}


extension TodoVC: UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text!.count >= 1 {
            sendButton.setImage(sendButtonEnableImage,for: .normal)
        }
        else{
            if traitCollection.userInterfaceStyle == .light {
                sendButton.setImage(UIImage(named: "btnSendInactive"), for: .normal)
            }
            else {
                sendButton.setImage(UIImage(named: "dkBtnSendInactive"), for: .normal)
            }
            
        }
    }
    
}

extension TodoVC: ToDoDelegate{
    func delete(idx: IndexPath){
        myDeleteRow(idx: idx,isEnd: false)
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: idx.row, section: idx.section)) as? TodoTVC else { return}
        
        cell.wasLongTapped = false
        self.showToast(text: "삭제되었어요.",withDelay: 0.6)
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas),forKey: "TodoDatas")
    }
    func modify(idx: IndexPath,str: String){
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: idx.row, section: idx.section)) as? TodoTVC else { return}
        
        cell.wasLongTapped = false
        
        todoDatas[idx.section][idx.row].todo = str
        wholeTV.reloadData()
        self.showToast(text: "수정되었어요",withDelay: 0.3)
        wholeTV.scrollToRow(at: idx, at: .middle, animated: true)
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas),forKey: "TodoDatas")
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
        print("aa")
        print(wholeTV.contentInset.bottom)
    }
    
}
