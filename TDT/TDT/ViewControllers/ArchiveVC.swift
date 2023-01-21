//
//  ArchiveVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import UIKit

class ArchiveVC: UIViewController {
    
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var archiveImage: UIImageView!
    @IBOutlet weak var wholeTV: UITableView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var mainButton: UIButton!
    let defaults = UserDefaults.standard
    var currentStatus = 0
    var archiveDatas: [[TodoData]] = []
    var dateInfo: [String] =  []
    var leftSwipe2 = UISwipeGestureRecognizer(target: self, action: #selector(leftSwiped2))
    var delaySection = -1
    var feedbackGenerator: UIImpactFeedbackGenerator?
    var emptyView = EmptyView(type: .archive)
    
    weak var pageControlDelegate: PageControlDelegate?
    
    var archiveImageNames = ["imgArchive","imgArchiveGr","imgArchiveYl","imgArchivePk"]
    var darkArchiveImageNames = ["dkImgArchive","dkImgArchiveGr","dkImgArchiveYl","dkImgArchivePk"]
    override func viewDidLoad() {
        super.viewDidLoad()
        wholeTV.delegate = self
        wholeTV.dataSource = self
        setItems()
        setData()
        currentStatus = 1
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setData()
        setMainColor()
        wholeTV.reloadData()
        currentStatus = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        wholeTV.reloadData()
        currentStatus = 0
    }
    override func viewWillDisappear(_ animated: Bool) {
        currentStatus = 1
        
    }
    
    func setMainColor(){
        if let mainColorIndex = defaults.value(forKey: "mainColor") as? Int {
            var archiveImageName = archiveImageNames[mainColorIndex]
            if traitCollection.userInterfaceStyle == .dark {
                archiveImageName = darkArchiveImageNames[mainColorIndex]
            }
            archiveImage.image = UIImage(named: archiveImageName)
           
        }
    }
    
    func setItems(){
        self.view.backgroundColor = UIColor(named: "bgColor")
        headerView.backgroundColor = UIColor(named: "bgColor")
        wholeTV.backgroundColor = UIColor(named: "bgColor")
        headerView.alpha = 0.95
        
        leftSwipe2 = UISwipeGestureRecognizer(target: self, action: #selector(leftSwiped2))
        leftSwipe2.direction = .left
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(leftSwipe2)
        self.feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        self.feedbackGenerator?.prepare()
        
        if traitCollection.userInterfaceStyle == .light {
            mainButton.setImage(UIImage(named: "btnMain"), for: .normal)
        }
        else {
            mainButton.setImage(UIImage(named: "dkBtnMain"), for: .normal)
        }
    }
    
    
    func setData(){
        
        if let savedData = defaults.value(forKey: "ArchiveDatas") as? Data{
            let originalData = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData)
            
            
            if originalData != nil{
                
                archiveDatas = originalData!
            }
            
        }
        
        
        if archiveDatas.count > 0 {
            
            if let tmpDate = defaults.stringArray(forKey: "ArchiveDates") {
                dateInfo = tmpDate
            }
            
            
        }
        wholeTV.reloadData()
        
    }
    @objc func leftSwiped2(){
        pageControlDelegate?.moveToViewController(to: 1)
    }
    func myDeleteRow(indexPath: IndexPath,isBack: Bool){
        wholeTV.beginUpdates()
        let inputTodo = archiveDatas[indexPath.section][indexPath.row]
        if isBack {
            if let todoDate = defaults.stringArray(forKey: "dates") {
                var tmpTodoDate = todoDate
                print("응응응1")
                if tmpTodoDate.count > 0 {
                    var flag = false
                    var inputIdx = -1
                    print("응응응2")
                    print(tmpTodoDate)
                    print(inputTodo.date)
                    for i in 0...tmpTodoDate.count-1 {
                        if inputTodo.date == tmpTodoDate[i] {
                            print("응응응3")
                            flag = true
                            if let savedData = defaults.value(forKey: "TodoDatas") as? Data{
                                let originalData = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData)
                                var tmpTodoDatas = originalData
                                print("응응응4")
                                tmpTodoDatas![i].append(inputTodo)
                                defaults.set(try? PropertyListEncoder().encode(tmpTodoDatas), forKey: "TodoDatas")
                                
                                break

                            }
                        }
                        else if inputTodo.date < tmpTodoDate[i] {
                            inputIdx = i
                            print("응응응5")
                            break
                        }
                        
                    }
                    if inputIdx == -1 {
                        inputIdx = todoDate.count
                    }
                    
                    if !flag {
                        if let savedData = defaults.value(forKey: "TodoDatas") as? Data{
                            let originalData = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData)
                            var tmpTodoDatas = originalData
                            
                            // 날짜 들어갈 위치 = inputIdx
                            tmpTodoDatas!.insert([inputTodo], at: inputIdx)
                            defaults.set(try? PropertyListEncoder().encode(tmpTodoDatas), forKey: "TodoDatas")
                            
                            tmpTodoDate.insert(inputTodo.date, at: inputIdx)
                            defaults.setValue(tmpTodoDate, forKey: "dates")
                        }
                        
                    }
                    
                }
                
                else {
                    if let savedData = defaults.value(forKey: "TodoDatas") as? Data{
                        let originalData = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData)
                        var tmpTodoDatas = originalData
                        tmpTodoDatas!.append([inputTodo])
                        defaults.set(try? PropertyListEncoder().encode(tmpTodoDatas), forKey: "TodoDatas")
                        
                        tmpTodoDate.append(inputTodo.date)
                        defaults.setValue(tmpTodoDate, forKey: "dates")
                    }
                    
                    
                    
                }
                
            }
            
            
        }
        
        archiveDatas[indexPath.section].remove(at: indexPath.row)
        
        
        
        // 삭제 (날짜 + 데이터)
        if archiveDatas[indexPath.section].count == 0{
            archiveDatas.remove(at: indexPath.section)
        }
        
        defaults.set(try? PropertyListEncoder().encode(archiveDatas), forKey: "ArchiveDatas")
        
        if wholeTV.numberOfRows(inSection: indexPath.section) == 1 {
            dateInfo.remove(at: indexPath.section)
            defaults.setValue(dateInfo, forKey: "ArchiveDates")
            wholeTV.deleteSections([indexPath.section], with: .fade)
        }
        else{
            wholeTV.deleteRows(at: [indexPath], with: .fade)
        }
        
        wholeTV.endUpdates()
        wholeTV.reloadData()
    }
    
    @IBAction func mainButtonAction(_ sender: Any) {
        pageControlDelegate?.moveToViewController(to: 1)
    }
}

extension ArchiveVC: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        switch currentStatus {
        
        // 뷰 처음 등장할때 오른쪽에서 왼쪽 가는 애니메이션
        case 1:
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
            
            
            
            
        default:
            return
            
        }
        
        
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        
        //                cell.alpha = 0.5
        
        switch currentStatus {
        
        // 뷰 처음 등장할때 오른쪽에서 왼쪽 가는 애니메이션
        case 1:
            cell.alpha = 0.2
            let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, -250, 0, 0)
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
            
            
            
            
        default:
            return
            
        }
        
        
        
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        
        if dateInfo[section] == dateString {
            let view = ArchiveFirstHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100))
            view.setDate(date: dateInfo[section]+" 한 일")
            view.startAnimation()
     
            
            return view
        }
        else {
            let view = FirstHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
            
            view.setDate(date: dateInfo[section]+" 한 일")
            return view
        }
        
     
        
        
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 100
        default:
            return 30
        }
    }
    
}

extension ArchiveVC: UITableViewDataSource{
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ArchiveTVC.identifier) as? ArchiveTVC else {return UITableViewCell()}
        
        cell.textBoxDelegate = self
        
        cell.myIndexpath = indexPath
        cell.setLabel(str: archiveDatas[indexPath.section][indexPath.row].todo)
        cell.isImportant = archiveDatas[indexPath.section][indexPath.row].isImportant
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
       
        
        cell.setItems()
        if dateInfo[indexPath.section] == dateString {
            cell.setLabelColor()
        }
        return cell
    }
    
  
    
    
    
}

extension ArchiveVC: TextBoxDelegate {
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
        defaults.set(try? PropertyListEncoder().encode(archiveDatas),forKey: "ArchiveDatas")
    }
    
    
}


extension ArchiveVC: UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        
    }
    
}

extension ArchiveVC: ToDoDelegate{
    func modify(indexPath: IndexPath, str: String) {
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? ArchiveTVC else { return}
        
        cell.wasLongTapped = false
        archiveDatas[indexPath.section][indexPath.row].todo = str
        defaults.set(try? PropertyListEncoder().encode(archiveDatas),forKey: "ArchiveDatas")
        wholeTV.reloadData()
        self.showToast(text: "수정되었어요",withDelay: 0.3)
    }
    
    func delete(indexPath: IndexPath){
        myDeleteRow(indexPath: indexPath,isBack: false)
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? ArchiveTVC else { return}
        
        cell.wasLongTapped = false
        
        self.showToast(text: "삭제되었어요.",withDelay: 0.6)
        
    }
    
    
    func dismissed(indexPath: IndexPath) {
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? ArchiveTVC else { return}
        print("왜?")
        cell.wasLongTapped = false
    }
    
}


extension ArchiveVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        
    }
    
}
