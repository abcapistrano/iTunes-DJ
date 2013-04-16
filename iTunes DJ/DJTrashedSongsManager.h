//
//  DJTrashedSongsManager.h
//  iTunes DJ
//
//  Created by Earl on 4/16/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DJTrashedSongsManager : NSWindowController
@property (strong) NSArray *songs;
- (id)initWithSongs: (NSArray *) songs;
- (IBAction)deleteSongs:(id)sender;
- (IBAction)cancel:(id)sender;
@end
