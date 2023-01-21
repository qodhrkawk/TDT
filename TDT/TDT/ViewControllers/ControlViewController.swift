//
//  ControlViewController.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import UIKit

class ControlViewController: UIViewController {
    var pageInstance : ControlPageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "controlSegue" {
            pageInstance = segue.destination as? ControlPageViewController

            guard let archiveVC = pageInstance?.viewControllerArray[0] as? ArchiveVC else { return }
            archiveVC.pageControlDelegate = self

            guard let todoViewController = pageInstance?.viewControllerArray[1] as? TodoViewController else { return }
            todoViewController.pageControlDelegate = self
        }
    }
}

extension ControlViewController: PageControlDelegate {
    func moveToViewController(to index: Int) {
        if index == 1 {
            pageInstance?.setViewControllers([(pageInstance?.viewControllerArray[1])!], direction: .forward,
            animated: true, completion: nil)
        }
        else {
            pageInstance?.setViewControllers([(pageInstance?.viewControllerArray[0])!], direction: .reverse,
            animated: true, completion: nil)
        }
    }
}
