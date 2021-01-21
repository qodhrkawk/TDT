//
//  TodoVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/21.
//

import UIKit

class TodoVC: UIViewController {
    
//    var myStr = "왼쪽으로 밀어서 완료 상태로 만들어 보세요.141414141414141414141414141414141414141414141414141414141414141414141414"
    var myStr = "왼쪽으로밀어서완료\naa"
    var isinit = true
    
    @IBOutlet weak var wholeTV: UITableView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        wholeTV.delegate = self
        wholeTV.dataSource = self
        
        
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        isinit = false
    }

 
}


extension TodoVC: UITableViewDelegate{
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       
        
        //                cell.alpha = 0.5
        if isinit{
            let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, 150, 0, 0)
            //                cell.layer.transform = rotate
            cell.layer.transform = rotationTransform
            UIView.animate(withDuration: 0.3,delay: 0.05 * Double(indexPath.row), animations: {
                cell.layer.transform = CATransform3DIdentity
            })
        }
       
    }
    
}

extension TodoVC: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodoTVC.identifier) as? TodoTVC else {return UITableViewCell()}
        
        cell.setLabel(str: myStr)
        return cell
    }
    
    
    
}
