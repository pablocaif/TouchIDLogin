//
//  QRCaptureViewController.m
//  TouchIDLogin
//
//  Created by Pablo Caif on 22/04/2015.
//  Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import "QRCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "TOTPTokenConfig.h"

@interface QRCaptureViewController ()<AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@end

@implementation QRCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startCapturing];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startCapturing {
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("QRCaptureQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.videoPreviewLayer setFrame:self.view.layer.bounds];
    [self.view.layer addSublayer:self.videoPreviewLayer];
    
    [self.captureSession startRunning];
}

- (void)stopCapturing {
    [self.captureSession stopRunning];
}

- (IBAction)cancelCapture:(id)sender {
    [self.qrCaptureDelegate didCancelOperation];
}

- (void)processCapturedString:(NSString *)capturedString {
    TOTPTokenConfig *tokenConfig = [[TOTPTokenConfig alloc] initWithTOTPURL:[NSURL URLWithString:capturedString]];
    [self.qrCaptureDelegate didCaptureTOTPSecret:tokenConfig];
    
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = metadataObjects[0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            
            [self performSelectorOnMainThread:@selector(stopCapturing) withObject:nil waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(processCapturedString:) withObject:[metadataObj stringValue] waitUntilDone:YES];
            
        }
    }
}

@end
