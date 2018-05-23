/*
    Copyright (c) 2012-2018 Ricci Adams

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

#import <Foundation/Foundation.h>

#import "AppleSPI.h"
#import "HelperProtocol.h"


@interface Helper : NSObject <NSXPCListenerDelegate, HelperProtocol>
@end

@implementation Helper {
    NSXPCListener *_listener;
}


- (instancetype) init
{
    if (self = [super init]) {
        _listener = [[NSXPCListener alloc] initWithMachServiceName:kHelperMachServiceName];
        [_listener setDelegate:self];
    }

    return self;
}


- (void) run
{
    [_listener resume];
    [[NSRunLoop currentRunLoop] run];
}


- (BOOL) listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    [newConnection setExportedInterface:[NSXPCInterface interfaceWithProtocol:@protocol(HelperProtocol)]];
    [newConnection setExportedObject:self];
    [newConnection resume];
    
    return YES;
}


- (void) preventSleepWithReply:(void (^)(NSInteger error))reply
{
    NSInteger status = IOPMSetSystemPowerSetting(kIOPMSleepDisabledKey, kCFBooleanTrue);
    if (reply) reply(status);
}


- (void) allowSleepWithReply:(void (^)(NSInteger error))reply
{
    NSInteger status = IOPMSetSystemPowerSetting(kIOPMSleepDisabledKey, kCFBooleanFalse);
    if (reply) reply(status);
}


- (void) requestVersionWithReply:(void (^)(NSInteger version))reply
{
    if (reply) reply(kHelperVersion);
}


@end


int main(int argc, char *argv[])
{
    @autoreleasepool {
        Helper *helper = [[Helper alloc] init];
        [helper run];
    }

    return 0;
}

