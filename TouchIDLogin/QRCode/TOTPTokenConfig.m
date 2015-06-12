//
// Created by Pablo Caif on 22/04/15.
// Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import "TOTPTokenConfig.h"


@implementation TOTPTokenConfig {

}


- (instancetype)initWithTOTPURL:(NSURL *)totpUrl {
    self = [super init];
    if (self != nil) {
        if ([[totpUrl host] isEqualToString:@"totp"] && [[totpUrl scheme] isEqualToString:@"otpauth"]) {
            self.accountName = [totpUrl lastPathComponent];
            NSString *queryString = [totpUrl query];
            NSArray *parameters = [queryString componentsSeparatedByString:@"&"];
            for (NSString *parameter in parameters) {
                NSArray *parsedParameter = [parameter componentsSeparatedByString:@"="];
                if (parsedParameter.count == 2 && [parsedParameter[0] isEqualToString:@"secret"]) {
                    self.totpSecret = parsedParameter[1];
                } else if (parsedParameter.count == 2 && [parsedParameter[0] isEqualToString:@"issuer"]) {
                    self.siteName = parsedParameter[1];
                }
            }
        }
    }
    return self;
}


@end