//
//  UIViewController+Extensions.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showToast(text: String, withDelay: CGFloat){
        let toast = ToastView(frame: CGRect(x: 0, y: 0, width: 125, height: 35))
        toast.setLabel(text: text)
        toast.alpha = 0
        self.view.addSubview(toast)
        
        toast.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-114)
            $0.width.equalTo(125)
            $0.height.equalTo(35)
        }
        
        UIView.animate(withDuration: 0.3, delay:  TimeInterval(withDelay), animations: {
            toast.alpha = 1
        },completion: { finish in
            UIView.animate(withDuration: 0.3, delay: 0.7, animations: {
                toast.alpha = 0
            })
        })
    }
    
    func adjustToUserInterfaceStyle() {
        switch TraitInfoManager.shared.currentTraitInfo {
        case .light:
            overrideUserInterfaceStyle = .light
        case .dark:
            overrideUserInterfaceStyle = .dark
        default:
            overrideUserInterfaceStyle = .unspecified
        }
    }
}
