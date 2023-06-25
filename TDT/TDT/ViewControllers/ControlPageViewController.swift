import UIKit

class ControlPageViewController: UIPageViewController {
    let identifiers = ["ArchiveViewController","TodoViewController"]
    var currentViewController: UIViewController?

    lazy var viewControllerArray : [UIViewController] = {
        return [
            self.viewControllerInstance(storyboardName: "Archive", viewControllerName: "ArchiveViewController"),
            self.viewControllerInstance(storyboardName: "Todo", viewControllerName: "TodoViewController")
        ]
    }()
    
    private func viewControllerInstance(storyboardName : String, viewControllerName : String) -> UIViewController {
        UIStoryboard(name : storyboardName, bundle : nil).instantiateViewController(withIdentifier: viewControllerName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self

        currentViewController = viewControllerArray[1]
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
            currentViewController = viewControllerArray[previousIndex]
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
            currentViewController = viewControllerArray[nextIndex]
            return viewControllerArray[nextIndex]
        }
    }
}


