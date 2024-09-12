// (c) 2017-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Cocoa/Cocoa.h>

@interface LaunchFermataAppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation LaunchFermataAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSArray *runningApplications = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.iccir.Fermata"];
    BOOL     needsLaunch         = [runningApplications count] == 0;
    
    if (needsLaunch) {
        NSString       *path       = [[NSBundle mainBundle] bundlePath];
        NSMutableArray *components = [[path pathComponents] mutableCopy];

        [components removeLastObject];
        [components removeLastObject];
        [components removeLastObject];
        [components removeLastObject];

        NSString *appPath = [NSString pathWithComponents:components];
        [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    }

    [NSApp terminate:nil];
}

@end


int main(int argc, const char * argv[])
{
@autoreleasepool {
    NSApplication *application = [NSApplication sharedApplication];
    LaunchFermataAppDelegate *appDelegate = [[LaunchFermataAppDelegate alloc] init];
    
    [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [application setDelegate:appDelegate];
    [application run];
    
}
    return 0;
}


