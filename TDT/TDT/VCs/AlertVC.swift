//
//  AlertVC.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/23.
//

import UIKit

class AlertVC: UIViewController {
    
    @IBOutlet weak var changeButton: UIButton!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black60
        setButtons()
        // Do any additional setup after loading the view.
    }
    
    func setButtons(){
//        cancelButton.makeRounded(cornerRadius: 6)
        
        cancelButton.backgroundColor = .white
        deleteButton.backgroundColor = .white
        changeButton.backgroundColor = .white
       
        
    }


    @IBAction func cancelButtonAction(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    

  
}
