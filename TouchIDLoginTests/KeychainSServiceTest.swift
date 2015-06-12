//
//  KeychainSService.swift
//  TouchIDLogin
//
//  Created by Pablo Caif on 11/06/2015.
//  Copyright (c) 2015 Pablo Caif. All rights reserved.
//

import UIKit
import XCTest
import TouchIDLogin

class KeychainSServiceTest: XCTestCase {
    
    var keychainService :KeychainSService?
    
    override func setUp() {
        super.setUp()
        keychainService = KeychainSService(serviceName: "testDomain")
        keychainService?.deletePasswordForUser("testUser", error : nil)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        keychainService?.setPasswordWithACLForTouchID(forUser: "testUser", password: "password", error: nil)
        let password = keychainService?.retrievePasswordForUser("testUser", prompt: "provide password", error: nil)
        XCTAssert(password == "password", "Pass")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
