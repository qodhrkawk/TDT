//
//  AppDelegate.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    private func migrateUserDefaultsIfNeeded() {
        guard let _ = UserDefaults.grouped.value(forKey: "UserDefaultsMigrated") else {
            UserDefaults.standard.dictionaryRepresentation().forEach { (key, value) in
                UserDefaults.grouped.set(value, forKey: key)
            }
            
            UserDefaults.grouped.setValue("migrated", forKey: "UserDefaultsMigrated")
            return
        }
        
    }

    func appUpdate() {

       // id뒤에 값은 앱정보에 Apple ID에 써있는 숫자

       if let url = URL(string: "itms-apps://itunes.apple.com/app/id1551113176"), UIApplication.shared.canOpenURL(url) {

          // 앱스토어로 이동

          if #available(iOS 10.0, *) {

             UIApplication.shared.open(url, options: [:], completionHandler: nil)

          } else {

              UIApplication.shared.openURL(url)

          }

       }

    }



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        migrateUserDefaultsIfNeeded()
        WidgetDataManager.shared.updateData()
        
        _ = try? AppStoreCheck.isUpdateAvailable { (update, error) in

           if let error = error {
              print(error)
           } else if let update = update {
            
              if update {
                 self.appUpdate()
                 return
              }
           }
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

