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
    
    var strs = ["왼쪽으로 밀어서 완료 상태로 만들어 보세요.ㅋ","두번 탭해서 중요 표시를 해 보세요.","길게 클릭해서 메모를 삭제하거나 수정할 수 있어요."]
    var isinit = true
    
    @IBOutlet weak var wholeTV: UITableView!
    
    @IBOutlet var longPressGesture: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wholeTV.delegate = self
        wholeTV.dataSource = self
        self.view.backgroundColor = .veryLightPink
        wholeTV.backgroundColor = .veryLightPink
        
        
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        isinit = true
    }
    override func viewDidAppear(_ animated: Bool) {
        isinit = false
    }
    
    
    @IBAction func longPressAction(_ sender: Any) {
       
       
    }
    
    
}


extension TodoVC: UITableViewDelegate{
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        
        //                cell.alpha = 0.5
        if isinit{
            //            let transformLayer = CATransformLayer()
            //            var perspective = CATransform3DIdentity
            ////            perspective.m34 = -1 / 500
            //            transformLayer.transform = perspective
            //            transformLayer.position = CGPoint(x: tableView.bounds.midX, y: tableView.bounds.midY)
            //            transformLayer.position = CGPoint(x: tableView.bounds.midX, y: tableView.bounds.midY)
            //            transformLayer.addSublayer(cell.layer)
            //            tableView.layer.addSublayer(transformLayer)
            ////            cell.layer.transform = CATransform3DMakeRotation(-0.5, 1, 0, 0)
            cell.alpha = 0.2
            let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, 250, 0, 0)
            //                cell.layer.transform = rotate
            //            cell.layer.transform = rotationTransform
            //            UIView.animate(withDuration: 0.9 - 0.07 * Double(indexPath.row),delay: 0.07 * Double(indexPath.row),options: .curveEaseOut, animations: {
            //                cell.alpha = 1
            //                cell.layer.transform = CATransform3DIdentity
            //            })
            cell.layer.transform = rotationTransform
            UIView.animate(withDuration: 0.4 ,delay: 0.05 * Double(indexPath.row),options: .curveEaseOut, animations: {
                cell.alpha = 1
                cell.layer.transform = CATransform3DIdentity
            })
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) as? TodoTVC else { return UISwipeActionsConfiguration()}
        cell.showDelete()
        
        
        
        print("callled")
        let deleteAction = UIContextualAction(style: .destructive, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in

            view.backgroundColor = .veryLightPink
            self.strs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            success(true)

        })
        
        
        deleteAction.image = UIImage(named: "imgDoggyThinking")
        deleteAction.backgroundColor = .veryLightPink
        let config = UISwipeActionsConfiguration(actions: [deleteAction])
       
            

        return UISwipeActionsConfiguration(actions:[deleteAction])

    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//
//
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
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
        return cell
    }
    
    
    
}

extension TodoVC: TextBoxDelegate {
    func longTapped() {
        guard let vcName = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(identifier: "AlertVC") as? AlertVC else {return}
      
        
        vcName.modalPresentationStyle = .overCurrentContext
        self.present(vcName, animated: false, completion: nil)
    }
    
}
