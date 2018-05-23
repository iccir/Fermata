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

#include <syslog.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h> 
#include <xpc/xpc.h>

#import "AppleSPI.h"


static void sPeerEventHandler(xpc_connection_t connection, xpc_object_t event)
{
    xpc_type_t type = xpc_get_type(event);
    
    if (type != XPC_TYPE_ERROR) {
        NSString *command = nil;
        
        const char *cString = xpc_dictionary_get_string(event, "command");
        
        if (!cString) {
            NSLog(@"Fermata Helper: sPeerEventHandler(): cString is NULL");
            return;
        }
        
        if (cString) {
            command = [[NSString alloc] initWithCString:cString encoding:NSUTF8StringEncoding];
        }

        BOOL ok = NO;
        IOReturn err = 0;

        if ([command isEqualToString:@"prevent"]) {
            err = IOPMSetSystemPowerSetting(kIOPMSleepDisabledKey, kCFBooleanTrue);
            if (!err) ok = YES;

        } else if ([command isEqualToString:@"allow"]) {
            err = IOPMSetSystemPowerSetting(kIOPMSleepDisabledKey, kCFBooleanFalse);
            if (!err) ok = YES;

        } else if ([command isEqualToString:@"ping"]) {
            ok = YES;
        }

        xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
        
        xpc_object_t reply = xpc_dictionary_create_reply(event);
        xpc_dictionary_set_bool(reply,  "ok",     ok);
        xpc_dictionary_set_int64(reply, "error",  err);
        xpc_connection_send_message(remote, reply);
        
    } else {
        NSLog(@"Fermata Helper: sPeerEventHandler() received error event");
    }
}


static void sConnectionHandler(xpc_connection_t connection)
{
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        sPeerEventHandler(connection, event);
    });
    
    xpc_connection_resume(connection);
}


int main(int argc, char *argv[])
{
@autoreleasepool
{
    xpc_connection_t service = xpc_connection_create_mach_service("com.iccir.Fermata.Helper", dispatch_get_main_queue(), XPC_CONNECTION_MACH_SERVICE_LISTENER);
    
    if (!service) {
        syslog(LOG_NOTICE, "xpc_connection_create_mach_service() failed");
        exit(1);
    }
    
    xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
        sConnectionHandler(connection);
    });
    
    xpc_connection_resume(service);
    
    dispatch_main();
}
    return 0;
}

