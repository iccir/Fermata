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


#import "PreferencesController.h"
#import "Entry.h"


@import ServiceManagement;

@interface PreferencesController () 
@property (nonatomic) IBOutlet NSTableView *tableView;
@end

@implementation PreferencesController {
}

- (NSString *) windowNibName
{
    return @"Preferences";
}


- (IBAction) addEntry:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setAllowedFileTypes:@[ (__bridge id)kUTTypeApplicationBundle ]];
    
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseAbort) return;
        
        NSURL *URL = [openPanel URL];
        if (!URL) return;
        
        NSBundle *bundle = [NSBundle bundleWithURL:[openPanel URL]];

        if (bundle) {
            NSString *bundleIdentifier = [bundle bundleIdentifier];

            NSString *name = [[bundle localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
            if (!name) name = [[bundle infoDictionary] objectForKey:@"CFBundleDisplayName"];
            if (!name) name = [[bundle localizedInfoDictionary] objectForKey:@"CFBundleName"];
            if (!name) name = [[bundle infoDictionary] objectForKey:@"CFBundleName"];
            if (!name) name = bundleIdentifier;
            
            if (bundleIdentifier && name) {
                Entry *entry = [[Entry alloc] init];

                [entry setName:name];
                [entry setBundleIdentifier:bundleIdentifier];
                [entry setType:EntryTypePreventLidCloseSleepWhenIdleSleepPrevented];
                
                [_entryArrayController addObject:entry];
            }
        }
    }];
}


- (IBAction) removeEntry:(id)sender
{
    [_entryArrayController removeObjects:[_entryArrayController selectedObjects]];
    [_entryArrayController setSelectedObjects:@[ ]];
}


@end
