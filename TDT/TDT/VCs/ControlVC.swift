//
//  ControlVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import UIKit

class ControlVC: UIViewController {

    
    var pageInstance : ControlPVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "controlSegue"{
            pageInstance = segue.destination as? ControlPVC
//            pageInstance?.mainPageDelegate = self
            guard let archiveVC = pageInstance?.VCArray[0] as? ArchiveVC else {return}
            archiveVC.controlDelegate = self
            guard let todoVC = pageInstance?.VCArray[1] as? TodoVC else {return}
            todoVC.controlDelegate = self
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ControlVC: ControlDelegate{
    func moveTo(idx: Int) {
        if idx == 1{
            pageInstance?.setViewControllers([(pageInstance?.VCArray[1])!], direction: .forward,
            animated: true, completion: nil)
        }
        else{
            pageInstance?.setViewControllers([(pageInstance?.VCArray[0])!], direction: .reverse,
            animated: true, completion: nil)
        }
    }
}
