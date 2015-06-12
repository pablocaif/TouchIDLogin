//
//  KeychainService.h
//  TouchIDLogin
//
//  Created by Pablo Caif on 21/04/2015.
//  Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KeychainService : NSObject

@property (nonatomic, strong)NSString *serviceName;

- (instancetype)initWithServiceName:(NSString *)serviceName;

+ (instancetype)keychainServiceWithServiceName:(NSString *)serviceName;


- (void) setPasswordForUser:(NSString*)username password:(NSString*)password error:(NSError **)error;

- (NSString *)retrievePasswordForUser:(NSString *)username userPrompt:(NSString*)prompt error:(NSError **)error;

- (void)setPasswordWithACLForTouchIDUser:(NSString *)username password:(NSString *)password error:(NSError **)error;

- (NSString *) calculateSHA1:(NSString*)string;

- (void) deletePasswordForUser:(NSString *)username error:(NSError **)error;

@end
