//
//  LoginViewController.m
//  TouchIDLogin
//
//  Created by Pablo Caif on 16/04/2015.
//  Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import "LoginViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "QRCaptureViewController.h"
#import "TOTPTokenConfig.h"
#import "KeychainService.h"
#import "NetworkManager.h"
#import "AGTotp.h"
#import "AGBase32.h"

@interface LoginViewController ()<UITextFieldDelegate, QRCaptureViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *tokenField;
@property (weak, nonatomic) IBOutlet UISwitch *touchIDEnabled;
@property (strong, nonatomic)KeychainService *keychainService;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *token;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loggingIn;
@property (assign, nonatomic)BOOL needsToRememberCredentials;
@property (weak, nonatomic) IBOutlet UIButton *addTokenButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginButton.enabled = NO;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *touchIDOn = [userDefaults objectForKey:@"touchIDEnabled"];
    self.touchIDEnabled.on = [touchIDOn boolValue];
    self.username = [userDefaults objectForKey:@"username"];
    if (self.username != nil) {
        self.userField.text = self.username;
    }

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    self.keychainService = [KeychainService keychainServiceWithServiceName:@"touchIDTest"];
    [self shouldEnableAddToken];
    [self shouldEnableLogin];
}

- (void)shouldEnableAddToken {
    self.addTokenButton.enabled = [self validString:self.username];
}

- (void) dismissKeyboard {
    [self.userField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.tokenField resignFirstResponder];
}

- (void) shouldEnableLogin {
    self.loginButton.enabled = ([self validString:self.username] &&
            [self validString:self.password] &&
            [self validString:self.token] )||
            (self.touchIDEnabled.on && !self.needsToRememberCredentials);
}

- (BOOL)validString:(NSString *)stringValue {
    return stringValue != nil && stringValue.length > 0;
}

- (BOOL) canCheckBiometrics {
    LAContext *laContext = [[LAContext alloc] init];
    NSError *error = nil;
    if ([laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        return YES;
        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Touch ID not available" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertView show];
        return NO;
        
    }

}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"presentQRCapture"]) {
        UINavigationController *controller = (UINavigationController*)segue.destinationViewController;
        QRCaptureViewController *qrController = (QRCaptureViewController*)controller.topViewController;
        qrController.qrCaptureDelegate = self;
    }
}

- (IBAction)touchIdChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.touchIDEnabled.on forKey:@"touchIDEnabled"];
    if (self.touchIDEnabled.on) {
        self.needsToRememberCredentials = YES;
    } else {
        NSError *error = nil;
        [self.keychainService deletePasswordForUser:self.username
                                              error:&error];
        
        [self shouldPrintError:error];
    }
}

- (void)shouldPrintError:(NSError *)error {
    if (error) {
            NSLog(@"Error deleting passwords %@", [error localizedDescription]);
        }
}

- (IBAction)loginTapped:(id)sender {
    
    NetworkManager *networkManager = [NetworkManager getSharedNetworkManager];
    __weak LoginViewController *wSelf = self;
    if (self.touchIDEnabled.on && !self.needsToRememberCredentials) {
        [self loadCredentialsFromKeychain];
    } else {
        [networkManager loginWithUser:self.username
                             password:self.password
                                token:self.token
                       successHandler:^{
                           [wSelf saveCredentials];
                           [wSelf performSegueWithIdentifier:@"logginSuccess" sender:wSelf];
                       } errorHandler:^(NSString *errorMessage) {
                    [wSelf displayErrorMessage:errorMessage];
                }];
    }

}
-(void)continueLogin {
    NetworkManager *networkManager = [NetworkManager getSharedNetworkManager];
    __weak LoginViewController *wSelf = self;
    if ([self validString:self.token]) {
        [networkManager loginWithUser:wSelf.username
                             password:wSelf.password
                                token:wSelf.token
                       successHandler:^{
                           [wSelf performSegueWithIdentifier:@"logginSuccess" sender:wSelf];
                       } errorHandler:^(NSString *errorMessage) {
                           [wSelf displayErrorMessage:errorMessage];
                       }];
    } else {
        [self displayErrorMessage:@"Please enter token"];
    }

}
- (void)saveCredentials {
    NSError *error = nil;
    [[NSUserDefaults standardUserDefaults] setObject:self.username forKey:@"username"];
    [self.keychainService setPasswordWithACLForTouchIDUser:self.username
                                     password:self.password
                                       error:&error];
    if (error != nil) {
        NSLog(@"Error saving password %@",[error localizedDescription]);
    }

}

- (void)displayErrorMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)loadCredentialsFromKeychain {
    __weak LoginViewController *wSelf = self;
    LAContext *context = [[LAContext alloc] init];
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"Authenticate to access to the server" reply:^(BOOL success, NSError *error) {
        if (success) {
            NSError *error;
            wSelf.password = [wSelf.keychainService retrievePasswordForUser:self.username
                                                               userPrompt:@"Please authenticate"
                                                                    error:&error];
            [wSelf shouldPrintError:error];
            wSelf.passwordField.text = wSelf.password;
            
            NSString *totpSecret = [wSelf.keychainService retrievePasswordForUser:[NSString stringWithFormat:@"%@-totp", wSelf.username]
                                                                      userPrompt:@""
                                                                           error:&error];
            
            AGTotp *agTotp = [[AGTotp alloc] initWithSecret:[AGBase32 base32Decode:totpSecret]];
            wSelf.token =  [agTotp generateOTP];
            [wSelf shouldPrintError:error];
            wSelf.tokenField.text = self.token;
            dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 500);
            dispatch_after(timeout, dispatch_get_main_queue(), ^{
                [wSelf continueLogin];
            });
            
        } else {
            if (error.code == LAErrorAuthenticationFailed || error.code == LAErrorUserFallback) {
                dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 500);
                dispatch_after(timeout, dispatch_get_main_queue(), ^{
                    [wSelf displayErrorMessage:@"Error authenticating please try again"];
                });
            }
            
        }
    }];

    

}

- (IBAction)addToken:(id)sender {

}


#pragma mark - QRCaptureDelegate

- (void)didCancelOperation {
    [self dismissViewControllerAnimated:YES completion:^{}];
    
}
- (void)didCaptureTOTPSecret:(TOTPTokenConfig *)totpTokenConfig {
    [self dismissViewControllerAnimated:YES completion:^{}];
    NSString *message = [NSString stringWithFormat:@"Got totp username=%@\n site=%@\n secret=%@", totpTokenConfig.accountName,
    totpTokenConfig.siteName, totpTokenConfig.totpSecret];

    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 500);
    dispatch_after(timeout, dispatch_get_main_queue(), ^{
        if (totpTokenConfig.totpSecret != nil) {
            NSError *error = nil;
            [self.keychainService setPasswordForUser:[NSString stringWithFormat:@"%@-totp", self.username]
             password:totpTokenConfig.totpSecret error:&error];
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Wohooo" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertView show];
    });


}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.userField]) {
        [self.passwordField becomeFirstResponder];
    } else if ([textField isEqual:self.passwordField]) {
        [self.tokenField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        return YES;
    }
    return NO;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isEqual:self.userField]) {
        self.username = textField.text;
        [self shouldEnableAddToken];
    } else if ([textField isEqual:self.passwordField]) {
        self.password = textField.text;
    } else if ([textField isEqual:self.tokenField]) {
        self.token = textField.text;
    }
    [self shouldEnableLogin];
}

@end
