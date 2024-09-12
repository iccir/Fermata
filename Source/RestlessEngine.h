// (c) 2017-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>


@interface RestlessEngine : NSObject

- (NSArray<NSNumber *> *) pidsPreventingIdleSleep;

- (void) checkHelper;

- (void) preventLidCloseSleep;
- (void) allowLidCloseSleepAfter:(NSTimeInterval)delay;

// For application termination
- (void) allowLidCloseSleepWithCallback:(void (^)(void))callback;

@property (nonatomic, readonly, getter=isPreventingLidCloseSleep) BOOL preventingLidCloseSleep;

@property (nonatomic) BOOL alsoPreventDiskSleep;
@property (nonatomic) BOOL alsoPreventDisplaySleep;

@end
