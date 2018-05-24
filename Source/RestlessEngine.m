/*
    Copyright (c) 2017-2018 Ricci Adams

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


#import "RestlessEngine.h"

#import "RestlessApplication.h"
#import "AppleSPI.h"
#import "HelperProtocol.h"

@import ServiceManagement;
@import IOKit.pwr_mgt;
@import AppKit;


@interface RestlessEngine ()
@property (nonatomic, getter=isPreventingLidCloseSleep) BOOL preventingLidCloseSleep;
@end


@implementation RestlessEngine {
    NSTimer *_timer;
    NSDictionary *_bundleIDToApplicationMap;
    
    NSTimeInterval _checkDate;
    NSInteger _helperVersion;
}


#pragma mark - Private Methods

- (BOOL) _attemptToBlessHelper
{

    AuthorizationItem   item   = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights rights = { 1, &item };
    AuthorizationFlags  flags  = kAuthorizationFlagDefaults           |
                                 kAuthorizationFlagInteractionAllowed |
                                 kAuthorizationFlagPreAuthorize       |
                                 kAuthorizationFlagExtendRights;

    AuthorizationRef authRef = NULL;

    OSStatus status = AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, flags, &authRef);

    if (status != errAuthorizationSuccess) {
        NSLog(@"AuthorizationCreate failed: %ld", (long)status);
        return NO;
    }

    CFErrorRef cfError = NULL;
    BOOL result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)kHelperMachServiceName, authRef, &cfError);

    if (!result || cfError) {
        NSError *error = CFBridgingRelease(cfError);
        NSLog(@"SMJobBless returned %ld: %@", (long)result, error);
        return NO;
    }
    
    return YES;
}


- (void) _launchHelperWithCommand:(NSString *)command reply:(void(^)(NSInteger))reply
{
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperMachServiceName options:NSXPCConnectionPrivileged];
    [connection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(HelperProtocol)]];

    [connection setInvalidationHandler:^{
        NSLog(@"Connection invalidation handler called.");
    }];

    [connection resume];
    
    id proxy = [connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"Couldn't get remote object: %@", error);
    }];
    
    __weak id weakSelf = self;
    
    void (^wrappedReply)(NSInteger) = ^(NSInteger arg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf _checkStatus];
        });

        if (reply) reply(arg);
    };
    
    if ([command isEqualToString:@"prevent"]) {
        [proxy preventSleepWithReply:wrappedReply];
        
    } else if ([command isEqualToString:@"allow"]) {
        [proxy allowSleepWithReply:wrappedReply];
    
    } else if ([command isEqualToString:@"version"]) {
        [proxy requestVersionWithReply:wrappedReply];
    }
}


- (void) _allowLidCloseSleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_allowLidCloseSleep) object:nil];
    [self _launchHelperWithCommand:@"allow" reply:nil];
}


- (void) _checkStatus
{
    NSDictionary *dictionary = CFBridgingRelease(IOPMCopySystemPowerSettings());
    
    BOOL isPreventingLidCloseSleep = [[dictionary objectForKey:(__bridge id)kIOPMSleepDisabledKey] boolValue];
    [self setPreventingLidCloseSleep:isPreventingLidCloseSleep];
}


- (void) _didReceiveHelperVersion:(NSInteger)version
{
    _helperVersion = version;
    [[NSUserDefaults standardUserDefaults] setInteger:version forKey:@"HelperVersion"];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_checkHelperVersionResult) object:nil];
    [self _checkHelperVersionResult];
}


- (void) _checkHelperVersionResult
{
    if (_helperVersion != kHelperVersion) {
        if (![self _attemptToBlessHelper]) {
            _helperVersion = 0;
        }
    }
}


#pragma mark - Public Methods

- (void) checkHelper
{
    __weak id weakSelf = self;

    NSInteger lastKnownHelperVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"HelperVersion"];
    
    if (lastKnownHelperVersion != kHelperVersion) {
        if (![self _attemptToBlessHelper]) {
            return;
        }
    } 
    
    [self _launchHelperWithCommand:@"version" reply:^(NSInteger version) {
        [weakSelf _didReceiveHelperVersion:version];
    }];

    [self performSelector:@selector(_checkHelperVersionResult) withObject:nil afterDelay:5.0];
}


- (NSArray<NSNumber *> *) pidsPreventingIdleSleep
{
    NSMutableArray *result = [NSMutableArray array];

    __block CFDictionaryRef cfAssertionsMap = NULL;
    IOReturn err = IOPMCopyAssertionsByProcess(&cfAssertionsMap);

    if (!err) {
        NSDictionary *assertionsMap = (__bridge id)cfAssertionsMap;
        for (NSNumber *pidNumber in assertionsMap) {
            NSArray *assertions = [assertionsMap objectForKey:pidNumber];
            
            for (NSDictionary *dictionary in assertions) {
                NSString *assertionType = [dictionary objectForKey:(__bridge id)kIOPMAssertionTypeKey];

                if ([assertionType isEqualToString:(__bridge id)kIOPMAssertPreventUserIdleSystemSleep] ||
                    [assertionType isEqualToString:(__bridge id)kIOPMAssertionTypeNoIdleSleep] ||
                    [assertionType isEqualToString:(__bridge id)kIOPMAssertionTypePreventSystemSleep]
                ) {
                    [result addObject:pidNumber];
                }
            }
        }
    } 
       
    if (cfAssertionsMap) CFRelease(cfAssertionsMap);

    return result;
}


- (void) allowLidCloseSleepWithCallback:(void (^)(void))callback
{
    if (_helperVersion) {
        [self _launchHelperWithCommand:@"allow" reply:^(NSInteger result) {
            callback();
        }];
    }
}


- (void) preventLidCloseSleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_allowLidCloseSleep) object:nil];
    [self _launchHelperWithCommand:@"prevent" reply:nil];
}


- (BOOL) isPreventingLidCloseSleep
{
    return _preventingLidCloseSleep;
}


- (void) allowLidCloseSleepAfter:(NSTimeInterval)delay
{
    [self performSelector:@selector(_allowLidCloseSleep) withObject:nil afterDelay:delay];
}


@end
