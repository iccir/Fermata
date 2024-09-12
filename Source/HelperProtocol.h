// (c) 2018-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

#define kHelperMachServiceName @"com.iccir.Fermata.Helper"
#define kHelperVersion 1

@protocol HelperProtocol
@required
- (void) preventSleepWithReply:(void (^)(NSInteger error))reply;
- (void) allowSleepWithReply:(void (^)(NSInteger error))reply;
- (void) requestVersionWithReply:(void (^)(NSInteger version))reply;
@end
