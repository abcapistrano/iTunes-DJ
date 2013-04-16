//
//  DJTrashedSongsManager.m
//  iTunes DJ
//
//  Created by Earl on 4/16/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "DJTrashedSongsManager.h"

@interface DJTrashedSongsManager ()

@end

@implementation DJTrashedSongsManager

- (id)initWithSongs:(NSArray *)songs
{
    self = [super initWithWindowNibName:@"TrashedSongsManager"];
    if (self) {

        _songs = songs;
        
    }
    return self;
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)deleteSongs:(id)sender {

    [self.window orderOut:self];
    [NSApp stopModalWithCode:NSOKButton];

}
- (IBAction)cancel:(id)sender {

    [self.window orderOut:self];
    [NSApp stopModalWithCode:NSCancelButton];
    
}

@end
