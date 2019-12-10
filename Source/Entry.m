/*
    Copyright (c) 2017-2019 Ricci Adams

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


#import "Entry.h"

NSString * const EntryDidUpdateNotification = @"EntryDidUpdateNotification";

@import AppKit;

static NSString *sNameKey             = @"name";
static NSString *sBundleIdentifierKey = @"bundle-identifier";
static NSString *sTypeKey             = @"action";


@implementation Entry

- (instancetype) initWithDictionary:(NSDictionary *)dictionary
{
    if ((self = [self init])) {
        _name             =  [dictionary objectForKey:sNameKey];
        _bundleIdentifier =  [dictionary objectForKey:sBundleIdentifierKey];
        _type             = [[dictionary objectForKey:sTypeKey] integerValue];
    }
    
    return self;
}


- (NSDictionary *) dictionaryRepresentation
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    if (_name)             [result setObject:_name             forKey:sNameKey];
    if (_bundleIdentifier) [result setObject:_bundleIdentifier forKey:sBundleIdentifierKey];
    if (_type)             [result setObject:@(_type)          forKey:sTypeKey];

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


- (void) setType:(EntryType)type
{
    if (_type != type) {
        _type = type;
        [[NSNotificationCenter defaultCenter] postNotificationName:EntryDidUpdateNotification object:self];
    }
}

@end
