// (c) 2018-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

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

