//
//  KeychainService.m
//  TouchIDLogin
//
//  Created by Pablo Caif on 21/04/2015.
//  Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import "KeychainService.h"
//#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>

@implementation KeychainService

- (instancetype)initWithServiceName:(NSString *)serviceName {
    self = [super init];
    if (self) {
        self.serviceName = serviceName;
    }

    return self;
}

+ (instancetype)keychainServiceWithServiceName:(NSString *)serviceName {
    return [[self alloc] initWithServiceName:serviceName];
}

- (void)setPasswordForUser:(NSString *)username password:(NSString *)password error:(NSError **)error {
    //First verify if the item exists
    if (![self itemExistsForUser:username]) {

        NSData *secret = [password dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *attributes = @{
                (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
                (__bridge id) kSecAttrService : self.serviceName,
                (__bridge id) kSecAttrAccount : username,
                (__bridge id) kSecValueData : secret
        };
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef) attributes, NULL);
        if (status) {
            *error = [[NSError alloc] initWithDomain:@"KeychainService" code:status userInfo:@{NSLocalizedDescriptionKey:
                    [self secErrorToStringValueForOSStatus:status]}];
        }
    } else {
        //Need to update the item
        [self updatePasswordForUser:username newPassword:password error:error];
    }
}

- (NSString *)retrievePasswordForUser:(NSString *)username userPrompt:(NSString *)prompt error:(NSError **)error {
    NSDictionary *query = @{
            (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
            (__bridge id) kSecAttrService : self.serviceName,
            (__bridge id) kSecAttrAccount : username,
            (__bridge id) kSecReturnData : @YES,
            (__bridge id)kSecUseOperationPrompt: prompt
    };
    CFTypeRef dataTypeRef = NULL;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, &dataTypeRef);
    if (status) {
        *error = [[NSError alloc] initWithDomain:@"KeychainService" code:status userInfo:@{NSLocalizedDescriptionKey:
                [self secErrorToStringValueForOSStatus:status]}];
    }
    NSData *password = (__bridge NSData *) dataTypeRef;
    return [NSString stringWithUTF8String:[password bytes]];
}

- (void)setPasswordWithACLForTouchIDUser:(NSString *)username
                                password:(NSString *)password
                                   error:(NSError **)error {
    //First verify if the item exists
    if (![self itemExistsForUser:username]) {
        CFErrorRef aclError = NULL;
        SecAccessControlRef accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, 0x00, &aclError);
        
        
        NSData *secret = [password dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *attributes = @{
                                     (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
                                     (__bridge id) kSecAttrService : self.serviceName,
                                     (__bridge id) kSecAttrAccount : username,
                                     (__bridge id) kSecValueData : secret,
                                     (__bridge id) kSecAttrAccessControl: (__bridge id)accessControl
                                     };
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef) attributes, NULL);
        if (status) {
            *error = [[NSError alloc] initWithDomain:@"KeychainService" code:status userInfo:@{NSLocalizedDescriptionKey:
                                                                                                   [self secErrorToStringValueForOSStatus:status]}];
        }
    } else {
        //Need to update the item
        [self updatePasswordForUser:username newPassword:password error:error];
    }
    
}

- (void)deletePasswordForUser:(NSString *)username error:(NSError **)error {
    NSDictionary *query = @{
            (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
            (__bridge id) kSecAttrService : self.serviceName,
            (__bridge id) kSecAttrAccount : username
    };

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef) query);
    if (status) {
        *error = [[NSError alloc] initWithDomain:@"KeychainService" code:status userInfo:@{NSLocalizedDescriptionKey:
                [self secErrorToStringValueForOSStatus:status]}];
    }
}


- (NSString *)calculateSHA1:(NSString *)string {
    NSString *secret = @"key";
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
    CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], result);

    NSMutableString *stringResult = [[NSMutableString alloc] initWithCapacity:20];
    for (int i = 0; i < 20; i++) {
        [stringResult appendString:[NSString stringWithFormat:@"%02x", result[i]]];
    }
    return stringResult;

    /*char base64Result[32];
    size_t theResultLength = 32;
    Base64EncodeData(result, 20, base64Result, &theResultLength);
    NSData *theData = [NSData dataWithBytes:base64Result length:theResultLength];

    NSString *base64EncodedResult = [[NSString alloc] initWithData:theData encoding:NSASCIIStringEncoding];

    return base64EncodedResult;*/
}


- (void)updatePasswordForUser:(NSString *)username newPassword:(NSString *)password error:(NSError **)pError {
    NSDictionary *query = @{
            (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
            (__bridge id) kSecAttrService : self.serviceName,
            (__bridge id) kSecAttrAccount : username
    };
    NSDictionary *update = @{(__bridge id) kSecValueData : [password dataUsingEncoding:NSUTF8StringEncoding]};

    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef) query, (__bridge CFDictionaryRef) update);
    if (status) {
        *pError = [[NSError alloc] initWithDomain:@"KeychainService" code:status userInfo:@{NSLocalizedDescriptionKey:
                [self secErrorToStringValueForOSStatus:status]}];
    }
}

- (BOOL)itemExistsForUser:(NSString *)username {
    NSDictionary *query = @{
            (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
            (__bridge id) kSecAttrService : self.serviceName,
            (__bridge id) kSecAttrAccount : username
    };
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, NULL);
    return status == errSecSuccess;
}

- (NSString *)secErrorToStringValueForOSStatus:(OSStatus)status {
    switch (status) {
        case errSecSuccess:
            return @"";
        case errSecUnimplemented:
            return @"Function or operation not implemented";
        case errSecIO:
            return @"I/O error";
        case errSecOpWr:
            return @"file already open with with write permission";
        case errSecParam:
            return @"One or more parameters passed to a function where not valid";
        case errSecAllocate:
            return @"Failed to allocate memory";
        case errSecUserCanceled:
            return @"User canceled the operation";
        case errSecBadReq:
            return @"Bad parameter or invalid state for operation";
        case errSecInternalComponent:
            return @"Internal component error";
        case errSecNotAvailable:
            return @"No keychain is available. You may need to restart your computer";
        case errSecDuplicateItem:
            return @"The specified item already exists in the keychain";
        case errSecItemNotFound:
            return @"The specified item could not be found in the keychain";
        case errSecInteractionNotAllowed:
            return @"User interaction is not allowed";
        case errSecDecode:
            return @"Unable to decode the provided data";
        case errSecAuthFailed:
            return @"Authentication failed";
        default:
            return @"Unknown error";
    }
}

@end
