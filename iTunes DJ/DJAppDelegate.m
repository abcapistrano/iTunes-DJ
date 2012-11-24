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
    
    NSMutableArray *specialPlaylists = [[userDefaults arrayForKey:CHOICESKEY] mutableCopy];
    
    
    if (specialPlaylists == nil || [specialPlaylists count] == 0) {
        
        
        
        
        //specialPlaylists = [@[ @"@Almost Forgotten", @"@Never Played", @"@Promoted" ] mutableCopy];
        specialPlaylists = [NSMutableArray array];
        
        for (NSString *playlistName in [playlists valueForKey:@"name"]) {
            
            if ([playlistName hasPrefix:@"@"]) {
                
                [specialPlaylists addObject:playlistName];
                
            }
            
        }
        

    }
    
    
    
    NSString *randomPlaylistName = [specialPlaylists grab:1][0];
    
    
    NSLog(@"chosen playlist: %@ #iTunesDJ", randomPlaylistName);
    
    [userDefaults setObject:specialPlaylists forKey:CHOICESKEY];
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
    
    
    [iTunesDJ playOnce:YES];
    
    

    [[NSApplication sharedApplication] terminate:nil];
        
    
    
    
    
}



@end