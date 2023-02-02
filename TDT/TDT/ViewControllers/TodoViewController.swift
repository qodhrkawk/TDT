//
//  TodoViewController.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/21.
//

import UIKit
import Combine

enum TodoAnimationStatus {
    case none
    case initialAnimation
    case sendAnimation
}

class TodoViewController: UIViewController {
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var todoTableView: UITableView!
    @IBOutlet weak var flickImageView: UIImageView!
    @IBOutlet weak var archiveButton: UIButton!
    
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var todoTableViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    weak var pageControlDelegate: PageControlDelegate?

    private let userDefaults = UserDefaults.standard
    private var dateInfo: [String] = []
    private var todoDatas: [[TodoData]] = []
    private var delaySection = -1
    private var animationStatus: TodoAnimationStatus = .initialAnimation
    
    private var previousKeyboardSize = CGRect(x: 0, y: 0, width: 0, height: 0)

    private var currentOffset = CGPoint(x: 0, y: 0)
    private var feedbackGenerator: UIImpactFeedbackGenerator?
    private var keyboardFlag = false

    private var rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwiped))
    private var emptyView = EmptyView(type: .main)
    
    private var mainColor: UIColor {
        guard let currentTheme = ThemeManager.shared.currentTheme else { return Theme.flickBlue.mainColor }
        return currentTheme.mainColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showGuideBoxesIfNeeded()

        setupTodoTableView()
        setupUIs()
        
        feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator?.prepare()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardSizeChangedNotification()
        animationStatus = .initialAnimation
        loadData()
        setMainColor()
        todoTableView.reloadData()
        registerForKeyboardNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        animationStatus = .none
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unregisterForKeyboardNotifications()
        unregisterKeyboardSizeChangedNotification()
        animationStatus = .initialAnimation
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction private func archiveButtonAction(_ sender: Any) {
        pageControlDelegate?.moveToViewController(to: 0)
    }

    @IBAction private func sendButtonAction(_ sender: Any) {
        if textField.text != ""{
            addData(todo: textField.text!)
            textField.text = ""
            animationStatus = .sendAnimation
        }
    }
    
    @IBAction private func settingButtonAction(_ sender: Any) {
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

// Extension about UI related methods
extension TodoViewController {
    private func setupUIs(){
        view.backgroundColor = Design.backgroundColor
        
        headerView.backgroundColor = Design.backgroundColor
        
        flickImageView.image = Design.flickImage

        headerView.alpha = 0.95

        textField.addLeftPadding(left: 7)
        textField.addRightPadding(right: 40)
        textField.placeholder = Design.TextField.placeHolder
        textField.font = Design.TextField.font
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange(sender:)), for: .editingChanged)
        textField.backgroundColor = Design.TextField.backgroundColor
        textField.textColor = Design.TextField.textColor
        
        view.isUserInteractionEnabled = true

        editView.setBorder(borderColor: Design.EditView.borderColor, borderWidth: 1.0)
        editView.backgroundColor = Design.EditView.backgrondColor

        rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwiped))
        rightSwipe.direction = .right

        view.addGestureRecognizer(rightSwipe)
        
        archiveButton.setImage(Design.Button.archiveButtonImage, for: .normal)
        archiveButton.tintColor = Design.Button.archiveButtonTintColor
        moreButton.setImage(Design.Button.moreButtonImage, for: .normal)
        moreButton.tintColor = Design.Button.archiveButtonTintColor
        
        sendButton.setImage(Design.Button.sendButtonImage, for: .normal)
        sendButton.tintColor = Design.Button.inactiveColor
    }
    
    private func setMainColor(){
        guard let theme = ThemeManager.shared.currentTheme else { return }
        
        flickImageView.tintColor = theme.mainColor
        
        if let text = textField.text, text.count > 0 {
            sendButton.tintColor = theme.mainColor
        }
    }
    
    private func setupTodoTableView(){
        todoTableView.delegate = self
        todoTableView.dataSource = self

        todoTableView.isUserInteractionEnabled = true
        todoTableView.backgroundColor = Design.backgroundColor
        
        let tableViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTouched))
        todoTableView.addGestureRecognizer(tableViewTapGesture)
    }
    
    @objc private func rightSwiped() {
        pageControlDelegate?.moveToViewController(to: 0)
    }
    
    @objc private func tableViewTouched(){
        self.view.endEditing(true)
    }
    
    @objc private func textFieldDidChange(sender:UITextField) {
        if let text = sender.text {
            // 초과되는 텍스트 제거
            if text.count >= 1 {
                sendButton.tintColor = mainColor
            }
            else {
                sendButton.setImage(Design.Button.sendButtonImage, for: .normal)
                sendButton.tintColor = Design.Button.inactiveColor
            }
        }
    }
}

// Extension about Keyboard animation
extension TodoViewController {
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func unregisterForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func registerKeyboardSizeChangedNotification(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardSizeChanged(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    private func unregisterKeyboardSizeChangedNotification(){
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
    }
    
    @objc private func keyboardSizeChanged(_ notification: NSNotification) {
        view.bringSubviewToFront(editView)
        keyboardFlag = true
        
        guard
            let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            keyboardSize.height != previousKeyboardSize.height
        else { return }
        
        previousKeyboardSize = keyboardSize
        
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self else { return }
            
            self.editView.transform = CGAffineTransform(translationX: 0, y: -(keyboardSize.height-29))
            
            self.currentOffset = self.todoTableView.contentOffset
            self.todoTableView.setContentOffset(
                CGPoint(
                    x: self.currentOffset.x,
                    y: self.currentOffset.y + keyboardSize.height - 29
                ),
                animated: false
            )
            self.todoTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height - 29, right: 0)
            self.todoTableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height - 29, right: 0)
            
        })
        
        view.layoutIfNeeded()
    }
    
    @objc private func keyboardWillShow(_ notification: NSNotification) {
        view.bringSubviewToFront(editView)
        
        guard keyboardFlag == false else { return }

        keyboardFlag = true
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }
                
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self else { return }
            
            self.editView.transform = CGAffineTransform(translationX: 0, y: -(keyboardSize.height-29))
            self.currentOffset = self.todoTableView.contentOffset

            self.todoTableView.setContentOffset(CGPoint(x: self.currentOffset.x, y: self.currentOffset.y + keyboardSize.height-29), animated: false)
            self.todoTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height-29, right: 0)
            self.todoTableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height-29, right: 0)
        })
        
        view.layoutIfNeeded()
    }
    
    @objc private func keyboardWillHide(_ notification: NSNotification) {
        guard keyboardFlag == true else { return }
        
        keyboardFlag = false

        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }

        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self else { return }
        
            self.editView.transform = .identity

            let goY = self.currentOffset.y > keyboardSize.height-29 ? self.currentOffset.y - (keyboardSize.height - 29) : 0

            self.todoTableView.contentInset = UIEdgeInsets(top: keyboardSize.height-29, left: 0, bottom: 0, right: 0)
            self.todoTableView.setContentOffset(CGPoint(x: self.currentOffset.x, y: goY), animated: true)
            self.todoTableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        })
        view.layoutIfNeeded()
        previousKeyboardSize = CGRect(x: 0, y: 0, width: 0, height: 0)
        todoTableView.contentInset = UIEdgeInsets(top:0, left: 0, bottom: 0, right: 0)
    }
}

// Extension about data
extension TodoViewController {
    private func loadData(){
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
        }
        todoTableView.reloadData()
    }
    
    private func showGuideBoxesIfNeeded() {
        if let _ = userDefaults.string(forKey: UserDefaultKeys.initiated.rawValue) {
            return
        }
        else {
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
            userDefaults.setValue("yes", forKey: UserDefaultKeys.initiated.rawValue)
        }
    }
    
    private func addData(todo: String){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        
        // 기존 데이터가 1개 이상
        if todoDatas.count > 0 {
            if let myDate = userDefaults.stringArray(forKey: "dates") {
                
                // 마지막이 같은 날짜이면
                if dateInfo[todoDatas.count-1] == dateString {
                    todoDatas[todoDatas.count-1].append(TodoData(date: dateString, todo: todo, isImportant: false))
                    
                }
                // 날짜 추가
                else{
                    var tmpDate = myDate
                    tmpDate.append(dateString)
                    userDefaults.setValue(tmpDate, forKey: "dates")
                    dateInfo.append(dateString)
                    todoDatas.append([TodoData(date: dateString, todo: todo, isImportant: false)])
                }
            }
        }
        
        else {
            let newDate = [dateString]
            userDefaults.setValue(newDate, forKey: "dates")
            todoDatas.append([TodoData(date: dateString, todo: todo, isImportant: false)])
            
            dateInfo.append(dateString)
        }
        
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas),forKey: "TodoDatas")
        todoTableView.reloadData()
    }
}



extension TodoViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        switch animationStatus {
        
        // 뷰 처음 등장할때 오른쪽에서 왼쪽 가는 애니메이션
        case .initialAnimation:
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
        

        switch animationStatus {
        // 뷰 처음 등장할때 오른쪽에서 왼쪽 가는 애니메이션
        case .initialAnimation:
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
            },completion: { [weak self] _ in
                self?.delaySection = -1
            })
            
            
        // 텍스트 추가될때 애니메이션
        case .sendAnimation:
            let lastIndexPath = IndexPath(row: tableView.numberOfRows(inSection: tableView.numberOfSections - 1) - 1, section: tableView.numberOfSections - 1)
            
            tableView.scrollToRow(at: lastIndexPath, at: .top, animated: false)
            let yMove = CGAffineTransform(translationX: 0, y: 300)

            cell.transform = yMove
            view.bringSubviewToFront(cell)
            if indexPath == lastIndexPath{
                UIView.animate(withDuration: 0.5 ,delay: 0 ,options: .curveEaseOut, animations: {
                    cell.alpha = 1
                    cell.transform = .identity
                },completion: { [weak self] _ in
                    self?.animationStatus = .none
                    
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
            let view = DateHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 103))
            view.setDate(date: dateInfo[section])
            return view
        default:
            let view = DateHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
            
            view.setDate(date: dateInfo[section])
            return view
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 103
        default:
            return 30
        }
    }
}

extension TodoViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TodoTableViewCell.identifier
        ) as? TodoTableViewCell else { return UITableViewCell() }

        cell.textBoxDelegate = self
        cell.todoData = todoDatas[indexPath.section][indexPath.row]        
        cell.myIndexpath = indexPath
        
        return cell
    }
}

extension TodoViewController: TextBoxDelegate {
    func longTapped(indexPath: IndexPath) {
        feedbackGenerator?.impactOccurred()
        guard let vcName = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(identifier: "AlertViewController") as? AlertViewController else {return}
        self.view.endEditing(true)
        vcName.contentText = todoDatas[indexPath.section][indexPath.row].todo
        vcName.fromArchive = false
        vcName.indexPath = indexPath
        vcName.todoDelegate = self
        vcName.modalPresentationStyle = .overCurrentContext
        
        
        self.present(vcName, animated: false, completion: nil)
    }
    
    func leftSwiped(indexPath: IndexPath) {
        myDeleteRow(indexPath: indexPath,isEnd: true)
    }

    func shouldMove() {
        pageControlDelegate?.moveToViewController(to: 0)
    }
    
    func doubleTapped(indexPath: IndexPath) {
        todoDatas[indexPath.section][indexPath.row].isImportant = !todoDatas[indexPath.section][indexPath.row].isImportant
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas), forKey: "TodoDatas")
        todoTableView.reloadData()
    }
    
    func myDeleteRow(indexPath: IndexPath,isEnd: Bool){
        todoTableView.beginUpdates()
        
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
                                archiveTmpData![i].append(todoDatas[indexPath.section][indexPath.row])
                            }
                        }
                        
                        // 날짜 추가해야함
                        if !flag {
                            archiveTmpData!.insert([todoDatas[indexPath.section][indexPath.row]], at: 0)
                            archiveTmpDate.insert(dateString, at: 0)

                        }
                        
                    }
                    else {
                        archiveTmpData = [[todoDatas[indexPath.section][indexPath.row]]]
                        archiveTmpDate = [dateString]
                        
                        userDefaults.setValue([dateString], forKey: "ArchiveDates")
                        
                    }
                    userDefaults.setValue(archiveTmpDate, forKey: "ArchiveDates")
                    
                }
                
                userDefaults.set(try? PropertyListEncoder().encode(archiveTmpData),forKey: "ArchiveDatas")
                
            }
            // 기존에 archive data 없음
            else {
                userDefaults.set(try? PropertyListEncoder().encode([[todoDatas[indexPath.section][indexPath.row]]]),forKey: "ArchiveDatas")
                userDefaults.setValue([dateString], forKey: "ArchiveDates")
            }

        }
        
        todoDatas[indexPath.section].remove(at: indexPath.row)
     
        // 삭제 (날짜 + 데이터)
        if todoDatas[indexPath.section].count == 0{
            todoDatas.remove(at: indexPath.section)
        }
        
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas), forKey: "TodoDatas")
        
        if todoTableView.numberOfRows(inSection: indexPath.section) == 1 {
            dateInfo.remove(at: indexPath.section)
            userDefaults.setValue(dateInfo, forKey: "dates")
            todoTableView.deleteSections([indexPath.section], with: .fade)
        }
        else{
            todoTableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        todoTableView.endUpdates()
        todoTableView.reloadData()
    }
}


extension TodoViewController: UITextFieldDelegate{
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text!.count >= 1 {
            sendButton.tintColor = mainColor
        }
        else{
            sendButton.setImage(Design.Button.sendButtonImage, for: .normal)
            sendButton.tintColor = Design.Button.inactiveColor
        }
    }
}

extension TodoViewController: ToDoDelegate {
    func delete(indexPath: IndexPath){
        myDeleteRow(indexPath: indexPath, isEnd: false)
        guard let cell = todoTableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? TodoTableViewCell else { return}
        
        cell.wasSingleTapped = false
        self.showToast(text: "삭제되었어요.",withDelay: 0.6)
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas),forKey: "TodoDatas")
    }
    func modify(indexPath: IndexPath, str: String){
        guard let cell = todoTableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? TodoTableViewCell else { return}
        
        cell.wasSingleTapped = false
        
        todoDatas[indexPath.section][indexPath.row].todo = str
        todoTableView.reloadData()
        self.showToast(text: "수정되었어요",withDelay: 0.3)
        todoTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas),forKey: "TodoDatas")
    }
    
    func dismissed(indexPath: IndexPath) {
        guard let cell = todoTableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? TodoTableViewCell else { return}
        cell.wasSingleTapped = false
    }
}


extension TodoViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        currentOffset = scrollView.contentOffset
    }
}

extension TodoViewController {
    enum Design {
        static let backgroundColor = UIColor(named: "bgColor")
        static let flickImage = UIImage(named: "imgLogo")?.withRenderingMode(.alwaysTemplate)
        
        enum TextField {
            static let font = UIFont(name: "GmarketSansTTFMedium", size: 15)
            static let backgroundColor = UIColor(named: "textBoxColor")
            static let textColor = UIColor(named: "typingTextColor")
            static let placeHolder = "해야 할 일을 입력해주세요."
        }
        
        enum EditView {
            static let borderColor = UIColor(named: "boxColor")
            static let backgrondColor = UIColor(named: "boxColor")
        }
        
        enum Button {
            static let archiveButtonImage = UIImage(named: "btnArchive")?.withRenderingMode(.alwaysTemplate)
            static let sendButtonImage = UIImage(named: "btnSendInactive")?.withRenderingMode(.alwaysTemplate)
            static let moreButtonImage = UIImage(named: "btnMore")?.withRenderingMode(.alwaysTemplate)

            static let archiveButtonTintColor = UIColor(named: "mainText")
            static let inactiveColor = UIColor(named: "inactive")
        }
    }
}
