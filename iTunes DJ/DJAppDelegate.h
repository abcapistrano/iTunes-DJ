//
//  DJAppDelegate.h
//  iTunes DJ
//
//  Created by Earl on 7/30/12.
//  Copyright (c) 2012 Earl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class iTunesApplication, iTunesUserPlaylist, SBElementArray;
@interface DJAppDelegate : NSObject  <NSApplicationDelegate, NSUserNotificationCenterDelegate>
@property (strong, readonly) iTunesApplication *iTunes;
@property (readonly) iTunesUserPlaylist *playlistOfTheDay;
@property (strong, readonly) SBElementArray *playlists;
@property (strong, readonly) SBElementArray *allTracks;
@end

