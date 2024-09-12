// (c) 2017-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

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
