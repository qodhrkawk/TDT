import UIKit

class ControlPageViewController: UIPageViewController {
    let identifiers = ["ArchiveVC","TodoVC"]

    lazy var viewControllerArray : [UIViewController] = {
        return [
            self.viewControllerInstance(storyboardName: "Archive", viewControllerName: "ArchiveVC"),
            self.viewControllerInstance(storyboardName: "Todo", viewControllerName: "TodoVC")
        ]
    }()
    
    private func viewControllerInstance(storyboardName : String, viewControllerName : String) -> UIViewController {
        UIStoryboard(name : storyboardName, bundle : nil).instantiateViewController(withIdentifier: viewControllerName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self

        setViewControllers([viewControllerArray[1]], direction: .forward, animated: true, completion: nil)
    }
}


extension ControlPageViewController : UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = viewControllerArray.firstIndex(of: viewController) else {return nil}
        
        let previousIndex = index - 1
    
        if previousIndex < 0 {
            return nil
        }
        else {
            return viewControllerArray[previousIndex]
        }
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = viewControllerArray.firstIndex(of: viewController) else { return nil }
        
        let nextIndex = index + 1

        if nextIndex >= viewControllerArray.count {
            return nil
        }
        else {
            return viewControllerArray[nextIndex]
        }
    }
}


