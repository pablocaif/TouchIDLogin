//
//  TIdViewController.swift
//  TouchIDLogin
//
//  Created by Pablo Caif on 12/06/2015.
//  Copyright (c) 2015 Pablo Caif. All rights reserved.
//

import UIKit
import LocalAuthentication

class TIdViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func retrieveSecret(sender: AnyObject) {
        let keycService = KeychainSService(serviceName: "MyDomain")
        let laContext = LAContext()
        var lerror : NSError?
        //lerror?.co
        let touchIDAvilable = laContext.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &lerror)
        if touchIDAvilable {
            laContext.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Please authenticate",
                reply: { (authenticated, error) -> Void in
                    if authenticated {
                        let password = keycService.retrievePasswordForUser("username", prompt: "Connect to Server", error: nil)
                        NSLog("Password =\(password)")
                    }
                    else {
                        let laError = LAError(rawValue: error.code)
                        
                        if laError ==  LAError.AuthenticationFailed {
                            NSLog("The authentication failed")
                        }
                    }
            })
        } else {
            //Show message TouchID not avilabe
        }

        
       
        
    }
    @IBAction func saveSecret(sender: AnyObject) {
        let keycService = KeychainSService(serviceName: "MyDomain")
        keycService.deletePasswordForUser("username", error: nil)
        keycService.setPasswordWithACLForTouchID(forUser: "username", password: "password", error: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
