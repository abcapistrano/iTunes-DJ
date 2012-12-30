//
//  DJAppDelegate.m
//  iTunes DJ
//
//  Created by Earl on 7/30/12.
//  Copyright (c) 2012 Earl. All rights reserved.
//

#import "DJAppDelegate.h"
#import "iTunes.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import "NSMutableArray+ConvenienceMethods.h"
NSString * const SPECIAL_PLAYLISTS_IDS_KEY = @"specialPlaylistsIDs";


@implementation DJAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.itunes"];
    
    SBElementArray *playlists = [[[iTunes sources] objectWithName:@"Library"] userPlaylists];

    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *specialPlaylistsIDs = [[userDefaults arrayForKey:SPECIAL_PLAYLISTS_IDS_KEY] mutableCopy];
    
    if (specialPlaylistsIDs == nil || specialPlaylistsIDs.count == 0 ) {
        
        
        specialPlaylistsIDs = [NSMutableArray array];
        
        for (iTunesUserPlaylist *p in playlists) {
            
            if ([p.name hasPrefix:@"@"]) {
                
                [specialPlaylistsIDs addObject:p.persistentID];
                
            }
            
        }
        
        
        
    }
    
    //
    
    NSString *randomID = [specialPlaylistsIDs grab:1][0];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"persistentID == %@", randomID];
    
    NSArray *results = [playlists filteredArrayUsingPredicate:pred];
    iTunesUserPlaylist *chosenPlaylist = results[0];
    [chosenPlaylist playOnce:YES];

    NSUserNotification *note = [NSUserNotification new];
    note.title = @"iTunes DJ";
    note.informativeText = [NSString stringWithFormat:@"Playlist \"%@\" is playing.", chosenPlaylist.name];
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];

    
    [userDefaults setObject:specialPlaylistsIDs forKey:SPECIAL_PLAYLISTS_IDS_KEY];
    [userDefaults synchronize];
    
    
    
    
    
    
    // Mark songs with 3-stars when the song is unrated (0 or 2 stars) and has a play count of 5 or more
    //    // Songs with less than 5 counts are unfamiliar songs
    SBElementArray *allSongs = [[playlists objectWithName:@"Music"] fileTracks];
    
    NSPredicate * rating = [NSPredicate predicateWithFormat:@"rating == 0 OR rating == 40"];
    NSPredicate * playedCount = [NSPredicate predicateWithFormat:@"playedCount > 4"];
    NSPredicate *combined = [NSCompoundPredicate andPredicateWithSubpredicates:@[rating, playedCount] ];
    
     NSArray* familiarSongs = [allSongs filteredArrayUsingPredicate:combined];


    for (iTunesTrack * track in familiarSongs) {
        track.rating = 60;
    }
    
    
    
    //sync ipod
    
    [iTunes update];
    
    
#ifdef RELEASE
    [[NSApplication sharedApplication] terminate:nil];
#endif
    
    
    
    
}


@end