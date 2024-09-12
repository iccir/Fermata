// (c) 2017-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

extern NSString * const EntryDidUpdateNotification;

typedef NS_ENUM(NSInteger, EntryType) {
    EntryTypeNone,
    EntryTypePreventLidCloseSleepWhenRunning,
    EntryTypePreventLidCloseSleepWhenIdleSleepPrevented
};


@interface Entry : NSObject

- (instancetype) initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bundleIdentifier;

@property (nonatomic) EntryType type;

@end
