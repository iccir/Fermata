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


#import "RestlessApplication.h"

NSString * const RestlessApplicationDidUpdateNotification = @"RestlessApplicationDidUpdateNotification";

@import AppKit;

static NSString *sNameKey             = @"name";
static NSString *sBundleIdentifierKey = @"bundle-identifier";
static NSString *sActionKey           = @"action";


@implementation RestlessApplication

- (instancetype) initWithDictionary:(NSDictionary *)dictionary
{
    if ((self = [self init])) {
        _name             =  [dictionary objectForKey:sNameKey];
        _bundleIdentifier =  [dictionary objectForKey:sBundleIdentifierKey];
        _action           = [[dictionary objectForKey:sActionKey] integerValue];
    }
    
    return self;
}


- (NSDictionary *) dictionaryRepresentation
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    if (_name)             [result setObject:_name             forKey:sNameKey];
    if (_bundleIdentifier) [result setObject:_bundleIdentifier forKey:sBundleIdentifierKey];
    if (_action)           [result setObject:@(_action)        forKey:sActionKey];

    return result;
}


- (NSImage *) image
{
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSString    *path      = [workspace absolutePathForAppBundleWithIdentifier:_bundleIdentifier];
    
    if (path) {
        return [workspace iconForFile:path];
    } else {
        return [workspace iconForFileType: (__bridge id)kUTTypeApplicationBundle];
    }
}


- (void) setAction:(RestlessAction)action
{
    if (_action != action) {
        _action = action;
        [[NSNotificationCenter defaultCenter] postNotificationName:RestlessApplicationDidUpdateNotification object:self];
    }
}

@end
