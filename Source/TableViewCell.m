//
//  TableViewCell.m
//  Fermata
//
//  Created by Ricci Adams on 2017-12-10.
//  Copyright © 2017 Ricci Adams. All rights reserved.
//

#import "TableViewCell.h"
#import "RestlessApplication.h"


@implementation TableViewCell


- (id) initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect])) {
        [self _setupTrackTableCellView];
    }
    
    return self;
}

- (void) awakeFromNib
{

}

- (IBAction) changeAction:(id)sender
{

}

- (RestlessApplication *) application
{
    return (RestlessApplication *)[self objectValue];
}

@end
