//
//  ArchiveViewController.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import UIKit

class ArchiveViewController: UIViewController {
    
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var archiveImage: UIImageView!
    @IBOutlet weak var wholeTV: UITableView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var mainButton: UIButton!
    
    weak var pageControlDelegate: PageControlDelegate?

    private let userDefaults = UserDefaults.standard
    private var animationStatus: TodoAnimationStatus = .initialAnimation
    private var archiveDatas: [[TodoData]] = []
    private var dateInfo: [String] =  []
    private var leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(viewLeftSwiped))
    private var delaySection = -1
    private var feedbackGenerator: UIImpactFeedbackGenerator?
    private var emptyView = EmptyView(type: .archive)

    override func viewDidLoad() {
        super.viewDidLoad()
        wholeTV.delegate = self
        wholeTV.dataSource = self
        setupUIs()
        setData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setData()
        wholeTV.reloadData()
        animationStatus = .initialAnimation
    }
    
    override func viewDidAppear(_ animated: Bool) {
        wholeTV.reloadData()
        animationStatus = .none
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        animationStatus = .initialAnimation
    }
    
    
    
    @IBAction private func mainButtonAction(_ sender: Any) {
        pageControlDelegate?.moveToViewController(to: 1)
    }
}

// Methods about UIs
extension ArchiveViewController {
    private func setupUIs(){
        view.backgroundColor = Design.Color.backgroundColor
        headerView.backgroundColor = Design.Color.backgroundColor
        wholeTV.backgroundColor = Design.Color.backgroundColor
        headerView.alpha = 0.95
        
        archiveImage.image = Design.Image.archiveImage
        
        leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(viewLeftSwiped))
        leftSwipe.direction = .left
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(leftSwipe)
        feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator?.prepare()
        
        if traitCollection.userInterfaceStyle == .light {
            mainButton.setImage(Design.Image.mainButtonImage, for: .normal)
        }
        else {
            mainButton.setImage(Design.Image.darkArchiveImage, for: .normal)
        }
    }
    
    @objc private func viewLeftSwiped(){
        pageControlDelegate?.moveToViewController(to: 1)
    }
}

// Methods about Data
extension ArchiveViewController {
    private func setData(){
        if let savedData = userDefaults.value(forKey: "ArchiveDatas") as? Data{
            let originalData = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData)
            
            if originalData != nil{
                archiveDatas = originalData!
            }
        }
        
        if archiveDatas.count > 0 {
            if let tmpDate = userDefaults.stringArray(forKey: "ArchiveDates") {
                dateInfo = tmpDate
            }
        }
        wholeTV.reloadData()
    }

    private func myDeleteRow(indexPath: IndexPath,isBack: Bool){
        wholeTV.beginUpdates()

        let inputTodo = archiveDatas[indexPath.section][indexPath.row]
        if isBack {
            if let todoDate = userDefaults.stringArray(forKey: "dates") {
                var tmpTodoDate = todoDate
                if tmpTodoDate.count > 0 {
                    var flag = false
                    var inputIdx = -1
                    for i in 0...tmpTodoDate.count-1 {
                        if inputTodo.date == tmpTodoDate[i] {
                            flag = true
                            if let savedData = userDefaults.value(forKey: "TodoDatas") as? Data{
                                let originalData = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData)
                                var tmpTodoDatas = originalData
                                tmpTodoDatas![i].append(inputTodo)
                                userDefaults.set(try? PropertyListEncoder().encode(tmpTodoDatas), forKey: "TodoDatas")
                                
                                break
                            }
                        }
                        else if inputTodo.date < tmpTodoDate[i] {
                            inputIdx = i
                            break
                        }
                    }
    
                    if inputIdx == -1 {
                        inputIdx = todoDate.count
                    }
                    
                    if !flag {
                        if let savedData = userDefaults.value(forKey: "TodoDatas") as? Data{
                            let originalData = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData)
                            var tmpTodoDatas = originalData
                            
                            // 날짜 들어갈 위치 = inputIdx
                            tmpTodoDatas!.insert([inputTodo], at: inputIdx)
                            userDefaults.set(try? PropertyListEncoder().encode(tmpTodoDatas), forKey: "TodoDatas")
                            
                            tmpTodoDate.insert(inputTodo.date, at: inputIdx)
                            userDefaults.setValue(tmpTodoDate, forKey: "dates")
                        }
                    }
                }
                else {
                    if let savedData = userDefaults.value(forKey: "TodoDatas") as? Data{
                        let originalData = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData)
                        var tmpTodoDatas = originalData
                        tmpTodoDatas!.append([inputTodo])
                        userDefaults.set(try? PropertyListEncoder().encode(tmpTodoDatas), forKey: "TodoDatas")
                        
                        tmpTodoDate.append(inputTodo.date)
                        userDefaults.setValue(tmpTodoDate, forKey: "dates")
                    }
                }
            }
        }
        
        archiveDatas[indexPath.section].remove(at: indexPath.row)
                
        // 삭제 (날짜 + 데이터)
        if archiveDatas[indexPath.section].count == 0{
            archiveDatas.remove(at: indexPath.section)
        }
        
        userDefaults.set(try? PropertyListEncoder().encode(archiveDatas), forKey: "ArchiveDatas")
        
        if wholeTV.numberOfRows(inSection: indexPath.section) == 1 {
            dateInfo.remove(at: indexPath.section)
            userDefaults.setValue(dateInfo, forKey: "ArchiveDates")
            wholeTV.deleteSections([indexPath.section], with: .fade)
        }
        else {
            wholeTV.deleteRows(at: [indexPath], with: .fade)
        }
        
        wholeTV.endUpdates()
        wholeTV.reloadData()
    }
}

extension ArchiveViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard animationStatus == .initialAnimation else { return }
        
        view.alpha = 0.2
        let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, -250, 0, 0)
        if delaySection == -1 {
            delaySection = section
        }
        
        view.layer.transform = rotationTransform
        let delay = 0.1 + 0.05 * Double(abs(section-delaySection))
        view.layer.transform = rotationTransform
        
        UIView.animate(withDuration: 0.4 ,delay: delay,options: .curveEaseOut, animations: {
            view.alpha = 1
            view.layer.transform = CATransform3DIdentity
        },completion: { f in
            self.delaySection = -1
        })
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard animationStatus == .initialAnimation else { return }
        
        cell.alpha = 0.2
        let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, -250, 0, 0)
        if delaySection == -1 {
            delaySection = indexPath.section
        }
        
        let delay = 0.1 + 0.05 * Double(abs(indexPath.section-delaySection)) + 0.02 * Double(indexPath.row)
        cell.layer.transform = rotationTransform
        UIView.animate(withDuration: 0.4, delay: delay, options: .curveEaseOut, animations: {
            cell.alpha = 1
            cell.layer.transform = CATransform3DIdentity
        },completion: { [weak self] _ in
            self?.delaySection = -1
        })
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        
        if dateInfo[section] == dateString {
            let view = DateHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 103))
            view.setDate(date: dateInfo[section]+" 한 일")
            view.highlightDateLabel()
     
            return view
        }
        else {
            let view = DateHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
            view.setDate(date: dateInfo[section]+" 한 일")
            
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

extension ArchiveViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return archiveDatas[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if archiveDatas.count == 0 {
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
        
        return archiveDatas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ArchiveTableViewCell.identifier) as? ArchiveTableViewCell else {return UITableViewCell()}
        
        cell.textBoxDelegate = self
        cell.myIndexpath = indexPath
        cell.todoData = archiveDatas[indexPath.section][indexPath.row]
       
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let date = Date()
        let dateString = dateFormatter.string(from: date)

        if dateInfo[indexPath.section] == dateString {
            cell.isToday = true
        }
        return cell
    }
}

extension ArchiveViewController: TextBoxDelegate {
    func longTapped(indexPath: IndexPath) {
        feedbackGenerator?.impactOccurred()
        self.view.endEditing(true)
        guard let vcName = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(identifier: "AlertViewController") as? AlertViewController else {return}
        
        vcName.contentText = archiveDatas[indexPath.section][indexPath.row].todo
        vcName.indexPath = indexPath
        vcName.todoDelegate = self
        vcName.fromArchive = true
        vcName.modalPresentationStyle = .overCurrentContext
        
        self.present(vcName, animated: false, completion: nil)
    }
    
    func leftSwiped(indexPath: IndexPath) {
        myDeleteRow(indexPath: indexPath, isBack: true)
    }
    
    func shouldMove() {
        pageControlDelegate?.moveToViewController(to: 1)
    }
    
    func doubleTapped(indexPath: IndexPath) {
        archiveDatas[indexPath.section][indexPath.row].isImportant = !archiveDatas[indexPath.section][indexPath.row].isImportant
        wholeTV.reloadData()
        userDefaults.set(try? PropertyListEncoder().encode(archiveDatas),forKey: "ArchiveDatas")
    }
}

extension ArchiveViewController: ToDoDelegate{
    func modify(indexPath: IndexPath, str: String) {
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? ArchiveTableViewCell else { return}
        
        cell.wasSingleTapped = false
        archiveDatas[indexPath.section][indexPath.row].todo = str
        userDefaults.set(try? PropertyListEncoder().encode(archiveDatas),forKey: "ArchiveDatas")
        wholeTV.reloadData()
        self.showToast(text: "수정되었어요",withDelay: 0.3)
    }
    
    func delete(indexPath: IndexPath){
        myDeleteRow(indexPath: indexPath,isBack: false)
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? ArchiveTableViewCell else { return}
        
        cell.wasSingleTapped = false
        
        self.showToast(text: "삭제되었어요.",withDelay: 0.6)
    }
    
    func dismissed(indexPath: IndexPath) {
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? ArchiveTableViewCell else { return}
        cell.wasSingleTapped = false
    }
    
}

extension ArchiveViewController {
    enum Design {
        enum Color {
            static let backgroundColor = UIColor(named: "bgColor")
        }
        
        enum Image {
            static let mainButtonImage = UIImage(named: "btnMain")
            static let archiveImage = UIImage(named: "imgArchive")
            static let darkArchiveImage = UIImage(named: "dkBtnMain")
        }
        
    }
}
