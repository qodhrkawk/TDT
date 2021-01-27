//
//  ArchiveVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import UIKit

class ArchiveVC: UIViewController {

    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var wholeTV: UITableView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var mainButton: UIButton!
    let defaults = UserDefaults.standard
    var currentStatus = 0
    var archiveData: WholeData?
    var dateInfo: [String] =  []
    
    
    var feedbackGenerator: UIImpactFeedbackGenerator?
//    var strs: [String] = []
//    var isImportant: [Bool] = []
    var strs = ["왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요.","왼쪽으로","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요."]

    var isImportant = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]
    
    var controlDelegate: ControlDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        wholeTV.delegate = self
        wholeTV.dataSource = self
        setItems()
        currentStatus = 1
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    func setItems(){
        self.view.backgroundColor = .veryLightPinkTwo
        headerView.backgroundColor = .veryLightPinkTwo
        wholeTV.backgroundColor = .veryLightPinkTwo
        headerView.alpha = 0.95
        
        
        self.feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        self.feedbackGenerator?.prepare()
    }

    func setData(){
        
        if let archiveData = defaults.value(forKey: "wholeData") as? Data{
            let originalData = try? PropertyListDecoder().decode(Dictionary<Int,[TodoData]>.self, from: archiveData)
     
            
            if originalData != nil{
           
                self.archiveData = WholeData(dict: originalData!)
            }
            
        }
        else {
            
            let emptyDict: Dictionary<Int,[TodoData]> = [:]
            defaults.setValue(emptyDict, forKey: "wholeData")
            self.archiveData = WholeData(dict: emptyDict)
        }
       
        
        
        wholeTV.reloadData()
        print(self.archiveData)
        
        if archiveData!.dict.count > 0 {
            for i in 0...archiveData!.dict.count-1 {
                let dateIdx = "archiveDate"+String(i)
                if let tmpDate = defaults.string(forKey: dateIdx) {
                    dateInfo.append(tmpDate)
                }
            }
            print(dateInfo)
            
        }
       
        
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
                        guard let cell = wholeTV.cellForRow(at: IndexPath(row: row, section: sec)) as? ArchiveTVC else { continue}
                        cell.myIndexpath = IndexPath(row: row, section: sec)
                    }
                }
                
                
            }
            else{
                if wholeTV.numberOfRows(inSection: sec) > 0 {
                    for row in 0...wholeTV.numberOfRows(inSection: sec)-1{
                        guard let cell = wholeTV.cellForRow(at: IndexPath(row: row, section: sec)) as? ArchiveTVC else { continue}
                        cell.myIndexpath = IndexPath(row: row, section: sec)
                    }
                }
            }
            
        }
    }
    
    @IBAction func mainButtonAction(_ sender: Any) {
        controlDelegate?.moveTo(idx: 1)
    }
    

}

extension ArchiveVC: UITableViewDelegate{
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        
        //                cell.alpha = 0.5
        
        switch currentStatus {
            
        // 뷰 처음 등장할때 오른쪽에서 왼쪽 가는 애니메이션
        case 1:
            cell.alpha = 0.2
            let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, -250, 0, 0)
     
            cell.layer.transform = rotationTransform
            UIView.animate(withDuration: 0.4 ,delay: 0.05 * Double(indexPath.row),options: .curveEaseOut, animations: {
                cell.alpha = 1
                cell.layer.transform = CATransform3DIdentity
            })
            
            
        
            
        default:
            return
        
        }
        
       
        
    }
    
    
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
    }
    
}

extension ArchiveVC: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return strs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ArchiveTVC.identifier) as? ArchiveTVC else {return UITableViewCell()}
        
        cell.textBoxDelegate = self
        cell.setLabel(str: strs[indexPath.row])
        cell.myIndexpath = indexPath
        cell.isImportant = isImportant[indexPath.row]
        cell.setItems()
        
        return cell
    }
    
    
    
}

extension ArchiveVC: TextBoxDelegate {
    func longTapped(idx: IndexPath) {
        feedbackGenerator?.impactOccurred()
        self.view.endEditing(true)
        guard let vcName = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(identifier: "AlertVC") as? AlertVC else {return}
        
        vcName.myText = strs[idx.row]
        vcName.idx = idx
        vcName.todoDelegate = self
        vcName.fromArchive = true
        vcName.modalPresentationStyle = .overCurrentContext
        
      
        self.present(vcName, animated: false, completion: nil)
    }
    
    func leftSwiped(idx: IndexPath) {
       
        myDeleteRow(idx: idx)
     

    }
    func shouldMove() {
        controlDelegate?.moveTo(idx: 1)
        
    }
    
    func doubleTapped(idx: IndexPath) {
        isImportant[idx.row] = !isImportant[idx.row]
        print(isImportant)
        wholeTV.reloadData()
      
    }
    
   
}


extension ArchiveVC: UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        
    }
    
}

extension ArchiveVC: ToDoDelegate{
    func modify(idx: IndexPath, str: String) {
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: idx.row, section: idx.section)) as? ArchiveTVC else { return}
       
        cell.wasLongTapped = false
        strs[idx.row] = str
        wholeTV.reloadData()
        self.showToast(text: "수정되었어요",withDelay: 0.3)
    }
    
    func delete(idx: IndexPath){
        myDeleteRow(idx: idx)
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: idx.row, section: idx.section)) as? ArchiveTVC else { return}
       
        cell.wasLongTapped = false
        self.showToast(text: "삭제되었어요.",withDelay: 0.6)
    }
   
    
    func disMissed(idx: IndexPath) {
        guard let cell = wholeTV.cellForRow(at: IndexPath(row: idx.row, section: idx.section)) as? ArchiveTVC else { return}
        print("왜?")
        cell.wasLongTapped = false
    }
    
}


extension ArchiveVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
     
    }
    
}
