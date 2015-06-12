//
// Created by Pablo Caif on 17/04/15.
// Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import "NetworkManager.h"

static NetworkManager *sharedNetworkManager = nil;
static NSString *const loginUrl = @"https://YourServer:8080/login";

@implementation NetworkManager

+ (NetworkManager *)getSharedNetworkManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sharedNetworkManager == nil) {
            sharedNetworkManager = [[self alloc] init];
        }
    });
    return sharedNetworkManager;
}

- (void)loginWithUser:(NSString *)user
             password:(NSString *)password
                token:(NSString *)token
       successHandler:(void (^)(void))successHandler
         errorHandler:(void (^)(NSString *errorMessage))errorHandler {
    
    NSURL *url = [NSURL URLWithString:loginUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *payload = [NSString stringWithFormat:@"username=%@&password=%@&TOTPKey=%@", user, password, token];
    
    request.HTTPBody = [payload dataUsingEncoding:NSUTF8StringEncoding];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse*) response;
        if (httpResponse.statusCode / 100 == 2) {
            successHandler();
        } else {
            NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Response string %@",responseStr);
            errorHandler(@"Error authenticating");
        }
        if (connectionError != nil) {
            errorHandler([connectionError localizedDescription]);
        }
    }];


}


@end