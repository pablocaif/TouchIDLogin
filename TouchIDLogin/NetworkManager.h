//
// Created by Pablo Caif on 17/04/15.
// Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NetworkManager : NSObject

+ (NetworkManager *)getSharedNetworkManager;

- (void) loginWithUser:(NSString *)user
              password:(NSString *)password
                 token:(NSString *)token
        successHandler:(void (^)(void)) successHandler
          errorHandler:(void (^) (NSString *errorMessage)) errorHandler;

@end