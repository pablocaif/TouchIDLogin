//
//  KeychainServiceTest.m
//  TouchIDLogin
//
//  Created by Pablo Caif on 21/04/2015.
//  Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "KeychainService.h"
#import "AGTotp.h"
#import "AGBase32.h"

@interface KeychainServiceTest : XCTestCase
@property(strong, nonatomic)KeychainService *testInstance;
@end

@implementation KeychainServiceTest

- (void)setUp {
    [super setUp];
    self.testInstance = [KeychainService keychainServiceWithServiceName:@"test"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testShouldStoreItemInKeychain {
    
    NSString *user = @"user";
    NSString *password = @"password";
    
    NSError *error = nil;
    [self.testInstance setPasswordForUser:user password:password error:&error];
    
    XCTAssert(error == nil, @"Pass");
    
    NSString* retrievedPassword = [self.testInstance retrievePasswordForUser:user userPrompt:@"test" error:&error];
    
    XCTAssert(error == nil);
    XCTAssert([retrievedPassword isEqual:password]);
}

- (void)testShouldUpdateKeychain {
    NSString *user = @"user";
    
    NSError *error = nil;
    [self.testInstance setPasswordForUser:user password:@"oldPassword" error:&error];
    
    NSString *newPassword = @"newPassword";
    [self.testInstance setPasswordForUser:user password:newPassword error:&error];
    
    NSString* retrievedPassword = [self.testInstance retrievePasswordForUser:user userPrompt:@"" error:&error];
    
    XCTAssert(error == nil);
    XCTAssert([retrievedPassword isEqual:newPassword]);
    
}

- (void)testEncoding {
    NSURL *totpURL = [NSURL URLWithString:@"otpauth://totp/APP:usert@domain.com?secret=Q74IFBT34FS7VGPU&issuer=APP"];
    NSLog(@"%@",[totpURL host]);
    NSLog(@"%@",[totpURL parameterString]);
    NSLog(@"%@",[totpURL pathComponents]);

    NSString *result = [self.testInstance calculateSHA1:@"password"];
    NSLog(@"%@", result);
}

- (void) testOTP {
    AGTotp *agOTP = [[AGTotp alloc] initWithSecret:[AGBase32 base32Decode:@"Q74IFBT34FS7VGPU"]];
    NSString *result = [agOTP generateOTP];
    XCTAssertNotNil(result);

}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        NSString *user = @"user";
        NSString *password = @"password";
        
        NSError *error = nil;
        [self.testInstance setPasswordForUser:user password:password error:&error];
    }];
}

@end
