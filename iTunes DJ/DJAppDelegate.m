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
NSString * const CHOICESKEY = @"PLAYLISTCHOICES";
@implementation DJAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.itunes"];

    
    SBElementArray *playlists = [[[iTunes sources] objectWithName:@"Library"] userPlaylists];
    iTunesUserPlaylist *iTunesDJ = [playlists objectWithName:@"iTunes DJ"];
    

    
    /*
     0 - represents the "Almost Forgotten Playlist"
     1 - represents the "Never pLayed" list
     2 - no list is added
     */
    
    
    /*
     
     Create the User defaults for the special playlists
     
     
     
     */
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *specialPlaylistNames = [[userDefaults arrayForKey:CHOICESKEY] mutableCopy];
    
    //Check playlists if they are empty; if yes, remove them from the choices.
    
    NSMutableArray *emptyPlaylistNames = [NSMutableArray array];
    for (NSString * playlistName in specialPlaylistNames) {
        
        iTunesUserPlaylist *thePlaylist = [playlists objectWithName:playlistName];
        
        if (thePlaylist.fileTracks.count == 0) {
            
            [emptyPlaylistNames addObject:playlistName];
            
            
        }
        
    }
    
    
    for (NSString * playlistName in emptyPlaylistNames) {
        
        [specialPlaylistNames removeObject:playlistName];
        
    }
    
    
    //
    
    if (specialPlaylistNames == nil || [specialPlaylistNames count] == 0) {
        
        specialPlaylistNames = [NSMutableArray array];
        for (NSString *playlistName in [playlists valueForKey:@"name"]) {
            
            if ([playlistName hasPrefix:@"@"]) {
                
                [specialPlaylistNames addObject:playlistName];
                
            }
            
        }
        

    }
    
    
    
    NSString *randomPlaylistName = [specialPlaylistNames grab:1][0];
    
    
    NSLog(@"chosen playlist: %@ #iTunesDJ", randomPlaylistName);
    
    [userDefaults setObject:specialPlaylistNames forKey:CHOICESKEY];
    [userDefaults synchronize];
    
    
    iTunesUserPlaylist *selectedPlaylist = [playlists objectWithName:randomPlaylistName];
    
    
    NSArray *newTracks = [selectedPlaylist fileTracks];
    
    // Add only those songs not in the playlist
    NSArray *ids = [[iTunesDJ fileTracks] valueForKey:@"databaseID"];
    NSMutableArray *urlsToAdd = [@[ ] mutableCopy];
    for (iTunesFileTrack *track in newTracks) {
        
        NSNumber *trackID = @ ([track databaseID]);
        
        if (![ids containsObject:trackID]) {
            
            [urlsToAdd addObject:[track location]];
            
        }
        
        
    }
    
    [iTunes add:urlsToAdd to:iTunesDJ];
    
    
    
    // Mark songs with 3-stars when the song is unrated and has a play count of 5 or more
    // Songs with less than 5 counts are unfamiliar songs
    
    SBElementArray *allSongs = [[playlists objectWithName:@"Music"] fileTracks];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"rating == 0 AND playedCount > 4"];
    NSArray* familiarSongs = [allSongs filteredArrayUsingPredicate:pred];
    
    
    for (iTunesTrack * track in familiarSongs) {
        track.rating = 60;
    }
    
    // Sync iPod
    
    
    
    [iTunes update];
    
    
    
    
    [iTunesDJ playOnce:YES];
    
#ifdef RELEASE
    [[NSApplication sharedApplication] terminate:nil];
#endif
    
    
    
    
}



@end