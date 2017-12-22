/*
    Copyright (c) 2017 Ricci Adams

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


@import IOKit.pwr_mgt;
@import AppKit;


@interface RestlessEngine ()
@property (nonatomic, getter=isPreventingLidCloseSleep) BOOL preventingLidCloseSleep;
@end


@implementation RestlessEngine {
    NSTimer *_timer;
    IOPMAssertionID _assertionID;
    NSDictionary *_bundleIDToApplicationMap;
}


#pragma mark - Private Methods

- (void) _allowLidCloseSleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_allowLidCloseSleep) object:nil];

    if (_assertionID) {
        IOPMAssertionRelease(_assertionID);
        _assertionID = kIOPMNullAssertionID;

        [self setPreventingLidCloseSleep:NO];
    }
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


- (void) preventLidCloseSleepWithDetailString:(NSString *)detailString
{
    /*
        See usage of kIOPMAssertionAppliesOnLidClose in IOKitUser and PowerManagement projects.
        This property is only valid for kIOPMAssertionUserIsActive (created by IOPMAssertionDeclareUserActivity).

        This sets the kAssertionLidStateModifier on the assertion, which eventually increments lidSleepCount
        in PMAssertions.c's setClamshellSleepState().
        
        When lidSleepCount is non-zero, kPMSetClamshellSleepState is eventually called with 0 (thus preventing
        sleep on lid close)
    */

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_allowLidCloseSleep) object:nil];

    IOReturn err = kIOReturnSuccess;
    
    if (!err) err = IOPMAssertionDeclareUserActivity(CFSTR("Fermata is preventing lid close sleep"), kIOPMUserActiveLocal, &_assertionID);
    if (!err) err = IOPMAssertionSetProperty(_assertionID, CFSTR("AppliesOnLidClose"), kCFBooleanTrue);
    
    if (!detailString) detailString = @"";
    if (!err) err = IOPMAssertionSetProperty(_assertionID, kIOPMAssertionDetailsKey, (__bridge CFStringRef)detailString);

    if (_assertionID) {
        [self setPreventingLidCloseSleep:YES];
    }

    if (err) {
        [self _allowLidCloseSleep];
    }
}


- (void) allowLidCloseSleepAfter:(NSTimeInterval)delay
{
    [self performSelector:@selector(_allowLidCloseSleep) withObject:nil afterDelay:delay];
}


@end
