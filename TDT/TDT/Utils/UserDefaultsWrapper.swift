//
//  UserDefaultsWrapper.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/21.
//

import Foundation

@propertyWrapper public struct UserDefaultWrapper<T: Codable> {
    public var wrappedValue: T? {
        get {
            guard let data = userDefaults.object(forKey: self.key) as? Data,
               let decoded = try? JSONDecoder().decode(T.self, from: data)
            else { return nil }
            
            return decoded
        }
        set {
            if newValue == nil { userDefaults.removeObject(forKey: key) }
            else {
                if let encoded = try? JSONEncoder().encode(newValue) {
                    userDefaults.setValue(encoded, forKey: key)
                }
            }
        }
    }
    
    public init(key: String, userDefaults: UserDefaults) {
        self.key = key
        self.userDefaults = userDefaults
    }
    
    private let key: String
    private let userDefaults: UserDefaults
}


@propertyWrapper public struct UserDefaultPropertyWrapper<T: Codable> {
    public var wrappedValue: T? {
        get {
            guard let data = userDefaults.object(forKey: self.key) as? Data,
               let decoded = try? JSONDecoder().decode(T.self, from: data)
            else { return nil }
            
            return decoded
        }
        set {
            if newValue == nil { userDefaults.removeObject(forKey: key) }
            else {
                if let encoded = try? JSONEncoder().encode(newValue) {
                    userDefaults.setValue(encoded, forKey: key)
                }
            }
        }
    }
    
    public init(key: String, userDefaults: UserDefaults) {
        self.key = key
        self.userDefaults = userDefaults
    }
    
    private let key: String
    private let userDefaults: UserDefaults
}
