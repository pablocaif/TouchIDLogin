//
//  QRCaptureViewController.h
//  TouchIDLogin
//
//  Created by Pablo Caif on 22/04/2015.
//  Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol QRCaptureViewControllerDelegate;
@class TOTPTokenConfig;

@interface QRCaptureViewController : UIViewController
@property(nonatomic, weak)id<QRCaptureViewControllerDelegate>qrCaptureDelegate;
@end

@protocol QRCaptureViewControllerDelegate <NSObject>

- (void)didCancelOperation;
- (void)didCaptureTOTPSecret:(TOTPTokenConfig *)totpTokenConfig;

@end
