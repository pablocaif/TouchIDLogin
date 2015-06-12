//
//  KeychainSService.swift
//  TouchIDLogin
//
//  Created by Pablo Caif on 11/06/2015.
//  Copyright (c) 2015 Pablo Caif. All rights reserved.
//

import Foundation
import Security

public class KeychainSService {
    var serviceName: String
    
    public init (serviceName: String) {
        self.serviceName = serviceName
    }
    
    public func setPassword(forUser username: String, password :String, error :NSErrorPointer?) -> Void {
        if !itemExistsForUser(username) {
            let secret :NSData  = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            let query :[String: AnyObject] = [
                String(kSecClass): kSecClassGenericPassword,
                String(kSecAttrService): serviceName,
                String(kSecAttrAccount): username,
                String(kSecValueData): secret
            ]
            let status = SecItemAdd(query, nil)
            if status != errSecSuccess {
                if (error != nil) {
                    error!.memory = NSError(domain: "KechainService", code: Int(status) , userInfo: [NSLocalizedDescriptionKey: secErrorToStringValue(status)])
                }
            }
        } else {
            updatePasswordForUser(username, newPassword: password, error: error)
        }
    }
    
    public func setPasswordWithACLForTouchID(forUser username: String, password :String, error :NSErrorPointer?) -> Void {
        if !itemExistsForUser(username) {
            var aclError: Unmanaged<CFErrorRef>?
            var accessControl :Unmanaged<SecAccessControl> = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, SecAccessControlCreateFlags.allZeros, &aclError)
            
            let secret :NSData  = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            
            let query :[String: AnyObject] = [
                String(kSecClass): kSecClassGenericPassword,
                String(kSecAttrService): serviceName,
                String(kSecAttrAccount): username,
                String(kSecValueData): secret,
                String(kSecAttrAccessControl) : accessControl.takeRetainedValue()
            ]
            let status = SecItemAdd(query, nil)
            if status != errSecSuccess {
                if (error != nil) {
                    error!.memory = NSError(domain: "KechainService", code: Int(status) , userInfo: [NSLocalizedDescriptionKey: secErrorToStringValue(status)])
                }
            }
        } else {
            updatePasswordForUser(username, newPassword: password, error: error)
        }
    }
    
    public func deletePasswordForUser(username :String, error :NSErrorPointer?) -> Void {
        let query  = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrService): serviceName ,
            String(kSecAttrAccount): username
        ]
    
        let status = SecItemDelete(query);
        if status != errSecSuccess {
            if (error != nil) {
                error!.memory = NSError(domain: "KechainService", code: Int(status) , userInfo: [NSLocalizedDescriptionKey: secErrorToStringValue(status)])
            }
        }
    }

    
   public func updatePasswordForUser(username : String, newPassword : String, error :NSErrorPointer?) -> Void {
        let query  = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrService): serviceName ,
            String(kSecAttrAccount): username 
        ]
        let passwordData : NSData = newPassword.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let updateDic : [String:AnyObject] = [String(kSecValueData): passwordData]
        let status = SecItemUpdate(query, updateDic)
        if status != errSecSuccess {
            if (error != nil) {
                error!.memory = NSError(domain: "KechainService", code: Int(status) , userInfo: [NSLocalizedDescriptionKey: secErrorToStringValue(status)])
            }
        }
        
    }
    
    public func retrievePasswordForUser(username :String, prompt :String, error :NSErrorPointer?) -> String {
        let returnData: NSNumber = true
        let query :[String:AnyObject]  = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrService): serviceName as CFString,
            String(kSecAttrAccount): username as CFString,
            String(kSecReturnData) : returnData,
            String(kSecUseOperationPrompt) : prompt
        ]
        var passwordPointer :Unmanaged<AnyObject>?
        let status = SecItemCopyMatching(query, &passwordPointer)
        if status != errSecSuccess {
            if (error != nil) {
                error!.memory = NSError(domain: "KechainService", code: Int(status) , userInfo: [NSLocalizedDescriptionKey: secErrorToStringValue(status)])
            }
        }
        if let passwordRetrieved = passwordPointer {
            let passwordData :NSData = passwordRetrieved.takeRetainedValue() as! NSData
            return  NSString(data: passwordData, encoding:NSUTF8StringEncoding) as! String
        }
        
        return ""
    }
    
    private func itemExistsForUser(username :String) -> Bool {
        let query  = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrService): serviceName as CFString,
            String(kSecAttrAccount): username as CFString
        ]
        
        let status = SecItemCopyMatching(query, nil)
        
        return status == errSecSuccess
    }
    
    private func secErrorToStringValue(status :OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return ""
        case errSecUnimplemented:
            return "Function or operation not implemented"
        case errSecParam:
            return "One or more parameters passed to a function where not valid"
        case errSecAllocate:
            return "Failed to allocate memory"
        case errSecNotAvailable:
            return "No keychain is available. You may need to restart your computer"
        case errSecDuplicateItem:
            return "The specified item already exists in the keychain"
        case errSecItemNotFound:
            return "The specified item could not be found in the keychain"
        case errSecInteractionNotAllowed:
            return "User interaction is not allowed"
        case errSecDecode:
            return "Unable to decode the provided data"
        case errSecAuthFailed:
            return "Authentication failed"
        default:
            return "Unknown error"
        }

    }
}