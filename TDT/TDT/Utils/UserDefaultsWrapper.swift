//
//  UserDefaultsWrapper.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/21.
//

import Foundation

@propertyWrapper struct UserDefaultWrapper<T: Codable> {
    var wrappedValue: T? {
        get {
            guard let data = UserDefaults.standard.object(forKey: self.key) as? Data,
               let decoded = try? JSONDecoder().decode(T.self, from: data)
            else { return nil }
            
            return decoded
        }
        set {
            if newValue == nil { UserDefaults.standard.removeObject(forKey: key) }
            else {
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.setValue(encoded, forKey: key)
                }
            }
        }
    }
    
    init(key: String) {
        self.key = key
    }
    
    private let key: String
}


@propertyWrapper struct UserDefaultPropertyWrapper<T: Codable> {
    var wrappedValue: T? {
        get {
            guard let data = UserDefaults.standard.object(forKey: self.key) as? Data,
               let decoded = try? JSONDecoder().decode(T.self, from: data)
            else { return nil }
            
            return decoded
        }
        set {
            if newValue == nil { UserDefaults.standard.removeObject(forKey: key) }
            else {
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.setValue(encoded, forKey: key)
                }
            }
        }
    }
    
    init(key: String) {
        self.key = key
    }
    
    private let key: String
}
