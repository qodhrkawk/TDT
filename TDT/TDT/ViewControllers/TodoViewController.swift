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

    private let userDefaults = UserDefaults.grouped
    private let store = TodoStore(userDefaults: .grouped)
    private var dateInfo: [String] { store.dateInfo }
    private var todoDatas: [[TodoData]] { store.todoDatas }
    private var delaySection = -1

    // 일괄 선택 모드
    private var isSelectionMode = false
    private var selectedIndexPaths = Set<IndexPath>()
    private lazy var selectionBar = makeSelectionBar()
    private let selectionCompleteButton = UIButton(type: .system)
    private let selectionDeleteButton = UIButton(type: .system)
    private let selectionCancelButton = UIButton(type: .system)
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
        registerForKeyboardNotifications()
        animationStatus = .initialAnimation
        view.endEditing(true)
        editView.transform = .identity
        loadData()
        setMainColor()
        todoTableView.reloadData()
        adjustToUserInterfaceStyle()
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard let previousTraitCollection else { return }
        if previousTraitCollection.userInterfaceStyle != traitCollection.userInterfaceStyle {
            userInterfaceStyleDidChange()
        }
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
        presentSettingViewController()
    }
    
    @objc private func presentSettingViewController() {
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
        flickImageView.isUserInteractionEnabled = true
        flickImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentSettingViewController)))

        headerView.alpha = 0.95
        
        textField.addLeftPadding(left: 7)
        textField.addRightPadding(right: 40)
        textField.makeRounded(cornerRadius: 8)
        textField.setBorder(borderColor: UIColor(named: "bgColor"), borderWidth: 1.0)
        textField.placeholder = Design.TextField.placeHolder
        textField.font = Design.TextField.font
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange(sender:)), for: .editingChanged)
        textField.backgroundColor = Design.TextField.backgroundColor
        textField.textColor = Design.TextField.textColor
        
        view.isUserInteractionEnabled = true

        editView.backgroundColor = Design.EditView.backgrondColor
        editView.dropShadow(color: UIColor(hexString: "#000000"), offSet: CGSize(width: 0, height: -2), opacity: 0.06, radius: 20 / UIScreen.main.scale)

        rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwiped))
        rightSwipe.direction = .right

        view.addGestureRecognizer(rightSwipe)
        
        archiveButton.setImage(Design.Button.archiveButtonImage, for: .normal)
        archiveButton.tintColor = Design.Button.archiveButtonTintColor
        moreButton.setImage(Design.Button.moreButtonImage, for: .normal)
        moreButton.tintColor = Design.Button.archiveButtonTintColor

        sendButton.setImage(Design.Button.sendButtonImage, for: .normal)
        sendButton.tintColor = Design.Button.inactiveColor

        setupMoreButtonMenu()
    }

    // 기존 스토리보드 액션(설정 바로 열기)을 메뉴로 대체 — 선택 모드 진입점 추가
    private func setupMoreButtonMenu() {
        moreButton.showsMenuAsPrimaryAction = true
        moreButton.menu = UIMenu(children: [
            UIAction(title: "선택", image: UIImage(systemName: "checkmark.circle")) { [weak self] _ in
                self?.enterSelectionMode()
            },
            UIAction(title: "설정", image: UIImage(systemName: "gearshape")) { [weak self] _ in
                self?.presentSettingViewController()
            }
        ])
    }
    
    private func userInterfaceStyleDidChange() {
        textField.setBorder(borderColor: UIColor(named: "bgColor"), borderWidth: 1.0)
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

        todoTableView.dragDelegate = self
        todoTableView.dropDelegate = self
        todoTableView.dragInteractionEnabled = true

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
    private var todayString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        return dateFormatter.string(from: Date())
    }

    private func loadData(){
        store.load()
        todoTableView.reloadData()
    }

    private func showGuideBoxesIfNeeded() {
        if let _ = userDefaults.string(forKey: UserDefaultKeys.initiated.rawValue) {
            return
        }
        else {
            let dateString = todayString
            store.load()
            store.add(todo: "왼쪽으로 밀어서 완료 상태로 만들어 보세요.", dateString: dateString)
            store.add(todo: "두 번 탭해서 중요 표시를 해 보세요.", dateString: dateString)
            store.add(todo: "한 번 클릭해서 메모를 삭제하거나 수정할 수 있어요.", dateString: dateString)
            userDefaults.setValue("yes", forKey: UserDefaultKeys.initiated.rawValue)
        }
    }

    private func addData(todo: String){
        store.add(todo: todo, dateString: todayString)
        todoTableView.reloadData()

        WidgetDataManager.shared.updateData()
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
            
            sendButton.tintColor = Design.Button.inactiveColor
            
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
        cell.isSelectionMode = isSelectionMode
        cell.isChecked = selectedIndexPaths.contains(indexPath)

        return cell
    }

    // 드래그 재정렬 — UIKit이 로컬 드래그를 이 메서드로 위임한다
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // 핀 그룹 클램프/빈 섹션 정리는 store가 담당한다.
        // UIKit이 그린 이동 결과와 달라질 수 있으므로 다음 런루프에서 정합화한다.
        store.move(from: sourceIndexPath, to: destinationIndexPath)
        WidgetDataManager.shared.updateData()

        DispatchQueue.main.async { [weak self] in
            self?.todoTableView.reloadData()
        }
    }
}

extension TodoViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard !isSelectionMode else { return [] }

        view.endEditing(true)
        feedbackGenerator?.impactOccurred()
        return [UIDragItem(itemProvider: NSItemProvider())]
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard session.localDragSession != nil else {
            return UITableViewDropProposal(operation: .cancel)
        }
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    // 로컬 단일 드래그는 moveRowAt으로 처리되므로 여기서 할 일 없음
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {}
}

extension TodoViewController: TextBoxDelegate {
    func longTapped(cell: UITableViewCell) {
        guard let indexPath = todoTableView.indexPath(for: cell) else { return }

        if isSelectionMode {
            toggleSelection(at: indexPath)
            return
        }

        feedbackGenerator?.impactOccurred()
        guard let vcName = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(identifier: "AlertViewController") as? AlertViewController else {return}
        self.view.endEditing(true)
        vcName.contentText = todoDatas[indexPath.section][indexPath.row].todo
        vcName.fromArchive = false
        vcName.showsPinAction = true
        vcName.isPinned = todoDatas[indexPath.section][indexPath.row].isPinned
        vcName.indexPath = indexPath
        vcName.todoDelegate = self
        vcName.modalPresentationStyle = .overCurrentContext


        self.present(vcName, animated: false, completion: nil)
    }

    func leftSwiped(cell: UITableViewCell) {
        guard !isSelectionMode,
              let indexPath = todoTableView.indexPath(for: cell)
        else { return }

        removeRow(at: indexPath, moveToArchive: true)
    }

    func shouldMove() {
        pageControlDelegate?.moveToViewController(to: 0)
    }

    func doubleTapped(cell: UITableViewCell) {
        guard !isSelectionMode,
              let indexPath = todoTableView.indexPath(for: cell)
        else { return }

        store.toggleImportant(at: indexPath)
        todoTableView.reloadData()

        WidgetDataManager.shared.updateData()
    }

    /// 한 항목 제거 — 완료(아카이브 이동) 또는 완전 삭제
    private func removeRow(at indexPath: IndexPath, moveToArchive: Bool) {
        if moveToArchive {
            guard let item = store.todo(at: indexPath) else { return }
            store.appendToArchive([item], dateString: todayString)
        }

        guard let result = store.remove(at: indexPath) else { return }

        todoTableView.beginUpdates()
        if result.sectionRemoved {
            todoTableView.deleteSections([indexPath.section], with: .fade)
        }
        else {
            todoTableView.deleteRows(at: [indexPath], with: .fade)
        }
        todoTableView.endUpdates()
        todoTableView.reloadData()

        WidgetDataManager.shared.updateData()
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
        removeRow(at: indexPath, moveToArchive: false)
        guard let cell = todoTableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? TodoTableViewCell else { return}

        cell.wasSingleTapped = false
        self.showToast(text: "삭제되었어요.",withDelay: 0.6)
    }
    func modify(indexPath: IndexPath, str: String){
        guard let cell = todoTableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? TodoTableViewCell else { return}

        cell.wasSingleTapped = false

        store.updateText(at: indexPath, text: str)
        todoTableView.reloadData()
        self.showToast(text: "수정되었어요",withDelay: 0.3)
        todoTableView.scrollToRow(at: indexPath, at: .middle, animated: true)

        WidgetDataManager.shared.updateData()
    }

    func dismissed(indexPath: IndexPath) {
        guard let cell = todoTableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? TodoTableViewCell else { return}
        cell.wasSingleTapped = false
    }

    func togglePin(indexPath: IndexPath) {
        guard let cell = todoTableView.cellForRow(at: indexPath) as? TodoTableViewCell else { return }
        cell.wasSingleTapped = false

        let wasPinned = store.todo(at: indexPath)?.isPinned ?? false
        guard let newIndexPath = store.togglePin(at: indexPath) else { return }

        todoTableView.reloadData()
        todoTableView.scrollToRow(at: newIndexPath, at: .middle, animated: true)
        self.showToast(text: wasPinned ? "고정이 해제되었어요." : "위로 고정했어요.", withDelay: 0.3)

        WidgetDataManager.shared.updateData()
    }
}

// MARK: - 일괄 선택 모드
extension TodoViewController {
    private func makeSelectionBar() -> UIView {
        let bar = UIView()
        bar.backgroundColor = Design.EditView.backgrondColor

        let font = UIFont(name: "GmarketSansTTFMedium", size: 15)

        selectionCancelButton.setTitle("취소", for: .normal)
        selectionCancelButton.titleLabel?.font = font
        selectionCancelButton.setTitleColor(UIColor(named: "mainText"), for: .normal)
        selectionCancelButton.addTarget(self, action: #selector(selectionCancelTapped), for: .touchUpInside)

        selectionCompleteButton.setTitle("완료", for: .normal)
        selectionCompleteButton.titleLabel?.font = font
        selectionCompleteButton.addTarget(self, action: #selector(selectionCompleteTapped), for: .touchUpInside)

        selectionDeleteButton.setTitle("삭제", for: .normal)
        selectionDeleteButton.titleLabel?.font = font
        selectionDeleteButton.setTitleColor(UIColor(named: "alertColor") ?? .systemRed, for: .normal)
        selectionDeleteButton.addTarget(self, action: #selector(selectionDeleteTapped), for: .touchUpInside)

        bar.addSubview(selectionCancelButton)
        bar.addSubview(selectionCompleteButton)
        bar.addSubview(selectionDeleteButton)

        selectionCancelButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalToSuperview().offset(14)
            $0.height.equalTo(30)
        }
        selectionDeleteButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-24)
            $0.centerY.equalTo(selectionCancelButton)
            $0.height.equalTo(30)
        }
        selectionCompleteButton.snp.makeConstraints {
            $0.trailing.equalTo(selectionDeleteButton.snp.leading).offset(-28)
            $0.centerY.equalTo(selectionCancelButton)
            $0.height.equalTo(30)
        }
        return bar
    }

    private func enterSelectionMode() {
        guard !isSelectionMode else { return }

        view.endEditing(true)
        isSelectionMode = true
        selectedIndexPaths.removeAll()

        if selectionBar.superview == nil {
            editView.addSubview(selectionBar)
            selectionBar.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
        selectionBar.isHidden = false
        updateSelectionButtons()

        animationStatus = .none
        todoTableView.reloadData()
    }

    private func exitSelectionMode() {
        isSelectionMode = false
        selectedIndexPaths.removeAll()
        selectionBar.isHidden = true
        todoTableView.reloadData()
    }

    private func toggleSelection(at indexPath: IndexPath) {
        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        }
        else {
            selectedIndexPaths.insert(indexPath)
        }

        if let cell = todoTableView.cellForRow(at: indexPath) as? TodoTableViewCell {
            cell.isChecked = selectedIndexPaths.contains(indexPath)
        }
        updateSelectionButtons()
    }

    private func updateSelectionButtons() {
        let count = selectedIndexPaths.count
        let hasSelection = count > 0

        selectionCompleteButton.setTitle(hasSelection ? "완료 \(count)" : "완료", for: .normal)
        selectionDeleteButton.setTitle(hasSelection ? "삭제 \(count)" : "삭제", for: .normal)
        selectionCompleteButton.isEnabled = hasSelection
        selectionDeleteButton.isEnabled = hasSelection
        selectionCompleteButton.setTitleColor(hasSelection ? mainColor : Design.Button.inactiveColor, for: .normal)
    }

    @objc private func selectionCancelTapped() {
        exitSelectionMode()
    }

    @objc private func selectionCompleteTapped() {
        guard !selectedIndexPaths.isEmpty else { return }

        let count = selectedIndexPaths.count
        store.batchArchive(at: Array(selectedIndexPaths), dateString: todayString)
        finishBatchAction(message: "\(count)개를 완료했어요.")
    }

    @objc private func selectionDeleteTapped() {
        guard !selectedIndexPaths.isEmpty else { return }

        let count = selectedIndexPaths.count
        let alert = UIAlertController(
            title: nil,
            message: "선택한 \(count)개를 삭제할까요?\n삭제하면 되돌릴 수 없어요.",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.store.batchDelete(at: Array(self.selectedIndexPaths))
            self.finishBatchAction(message: "\(count)개를 삭제했어요.")
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func finishBatchAction(message: String) {
        exitSelectionMode()
        WidgetDataManager.shared.updateData()
        showToast(text: message, withDelay: 0.3)
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
