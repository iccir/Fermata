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

@import ServiceManagement;
@import IOKit.pwr_mgt;
@import AppKit;

#define sHelperLabel "com.iccir.Fermata.Helper"


@interface RestlessEngine ()
@property (nonatomic, getter=isPreventingLidCloseSleep) BOOL preventingLidCloseSleep;
@end


@implementation RestlessEngine {
    NSTimer *_timer;
    NSDictionary *_bundleIDToApplicationMap;
}


#pragma mark - Private Methods

- (BOOL) _attempToBlessHelper:(NSError **)outError
{
    BOOL result = NO;

    AuthorizationItem   item   = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights rights = { 1, &item };
    AuthorizationFlags  flags  = kAuthorizationFlagDefaults           |
                                 kAuthorizationFlagInteractionAllowed |
                                 kAuthorizationFlagPreAuthorize       |
                                 kAuthorizationFlagExtendRights;

    AuthorizationRef authRef = NULL;
    
    OSStatus status = AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, flags, &authRef);

    if (status == errAuthorizationSuccess) {
        CFErrorRef cfError = NULL;
        result = SMJobBless(kSMDomainSystemLaunchd, CFSTR(sHelperLabel), authRef, &cfError);

        if (cfError) {
            NSError *nsError = CFBridgingRelease(cfError);
            if (outError) *outError = nsError;
        }
    }
    
    return result;
}


- (void) _launchHelperWithCommand:(NSString *)command callback:(void(^)(void))callback
{
    NSError *error = nil;

    // Attempt to create the connection to our helper tool
    xpc_connection_t connection = xpc_connection_create_mach_service(sHelperLabel, NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);

    // If we fail, we need to bless the helper
    if (!connection) {
        if ([self _attempToBlessHelper:&error]) {
            connection = xpc_connection_create_mach_service(sHelperLabel, NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
        }
    }
    
    // If we still fail, the user cancelled or something is wrong
    if (!connection) {
        [self setPreventingLidCloseSleep:NO];
        return;
    }

    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);
        
        if (type == XPC_TYPE_ERROR) {
            NSLog(@"Could not launch helper tool.");
        }
    });
    
    xpc_connection_resume(connection);
    
    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    
    xpc_dictionary_set_string(request, "command", [command UTF8String]);

    __weak id weakSelf = self;
    xpc_connection_send_message_with_reply(connection, request, dispatch_get_main_queue(), ^(xpc_object_t event) {
        [weakSelf _checkStatus];
        if (callback) callback();
    });
}


- (void) _allowLidCloseSleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_allowLidCloseSleep) object:nil];
    [self _launchHelperWithCommand:@"allow" callback:nil];
}


- (void) _checkStatus
{
    NSDictionary *dictionary = CFBridgingRelease(IOPMCopySystemPowerSettings());
    
    BOOL isPreventingLidCloseSleep = [[dictionary objectForKey:(__bridge id)kIOPMSleepDisabledKey] boolValue];
    [self setPreventingLidCloseSleep:isPreventingLidCloseSleep];
}


#pragma mark - Public Methods

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
    [self _launchHelperWithCommand:@"allow" callback:callback];
}


- (void) preventLidCloseSleep
{
    [self _launchHelperWithCommand:@"prevent" callback:nil];
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
