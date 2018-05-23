//
//  HelperProtocol.h
//  Fermata
//
//  Created by Ricci Adams on 2018-05-22.
//  Copyright © 2018 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kHelperMachServiceName @"com.iccir.Fermata.Helper"
#define kHelperVersion 1

@protocol HelperProtocol
@required
- (void) preventSleepWithReply:(void (^)(NSInteger error))reply;
- (void) allowSleepWithReply:(void (^)(NSInteger error))reply;
- (void) requestVersionWithReply:(void (^)(NSInteger version))reply;
@end
