//
// Created by Pablo Caif on 22/04/15.
// Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TOTPTokenConfig : NSObject

@property(nonatomic, strong)NSString *accountName;
@property(nonatomic, strong)NSString *siteName;
@property(nonatomic, strong)NSString *totpSecret;


- (instancetype)initWithTOTPURL:(NSURL *)totpUrl;

@end