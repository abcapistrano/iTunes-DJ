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
#import "NSDate+MoreDates.h"
NSString * const SPECIAL_PLAYLISTS_IDS_KEY = @"specialPlaylistsIDs";
NSString * const PLAYLIST_OF_THE_DAY_KEY = @"playlistOfTheDay";
NSString * const LAST_PLAYLIST_SETTING_DATE_KEY = @"lastPlaylistSettingDate";


@implementation DJAppDelegate
 
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.itunes"];

    iTunesUserPlaylist *playlistOfTheDay = self.playlistOfTheDay;
    [playlistOfTheDay playOnce:YES];

    [self showNotification];
    [self markFamiliarSongs];

    
        
    
    //sync ipod
    
    [self syncIpod];
    
#ifdef RELEASE
    [[NSApplication sharedApplication] terminate:nil];
#endif
    
    
    
    
}

- (iTunesUserPlaylist *) playlistOfTheDay {


    /* Set a new playlist of the day when:
     - the lastDate is stale
     - the lastDate is nil
     */



    self.playlists = [[[self.iTunes sources] objectWithName:@"Library"] userPlaylists];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSDate *lastPlaylistSettingDate = [userDefaults objectForKey:LAST_PLAYLIST_SETTING_DATE_KEY];
    NSString *playlistOfTheDayID;

    if (lastPlaylistSettingDate == nil || ![lastPlaylistSettingDate isSameDayAsDate:[NSDate date]]) {


        NSMutableArray *specialPlaylistsIDs = [[userDefaults arrayForKey:SPECIAL_PLAYLISTS_IDS_KEY] mutableCopy];
        if (specialPlaylistsIDs == nil || specialPlaylistsIDs.count == 0 ) {


            specialPlaylistsIDs = [NSMutableArray array];

            for (iTunesUserPlaylist *p in self.playlists) {

                if ([p.name hasPrefix:@"@"]) {

                    [specialPlaylistsIDs addObject:p.persistentID];

                }

            }



        }

        playlistOfTheDayID = [specialPlaylistsIDs grab:1][0];
        [userDefaults setValuesForKeysWithDictionary:@{
                             PLAYLIST_OF_THE_DAY_KEY:playlistOfTheDayID,
                           SPECIAL_PLAYLISTS_IDS_KEY:specialPlaylistsIDs,
                     LAST_PLAYLIST_SETTING_DATE_KEY : [NSDate date]} ];
        [userDefaults synchronize];


    } else {

        playlistOfTheDayID = [userDefaults objectForKey:PLAYLIST_OF_THE_DAY_KEY];



    }
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"persistentID == %@", playlistOfTheDayID];
    NSArray *results = [self.playlists filteredArrayUsingPredicate:pred];
    iTunesUserPlaylist *chosenPlaylist = results[0];
    return chosenPlaylist;
    
}

- (void) showNotification {
    NSUserNotification *note = [NSUserNotification new];
    note.title = @"iTunes DJ";
    note.informativeText = [NSString stringWithFormat:@"Playlist \"%@\" is playing.", self.playlistOfTheDay.name];

    NSUserNotificationCenter *nc = [NSUserNotificationCenter defaultUserNotificationCenter];
    [nc setDelegate:self];
    [nc deliverNotification:note];

    
}

-(void)syncIpod {

    [self.iTunes update];
}

-(void)markFamiliarSongs {

    // Mark songs with 3-stars when the song is unrated (0 or 2 stars) and has a play count of 5 or more
    //    // Songs with less than 5 counts are unfamiliar songs

    NSPredicate * rating = [NSPredicate predicateWithFormat:@"rating == 0 OR rating == 40"];
    NSPredicate * playedCount = [NSPredicate predicateWithFormat:@"playedCount > 4"];
    NSPredicate *combined = [NSCompoundPredicate andPredicateWithSubpredicates:@[rating, playedCount] ];

    NSArray* familiarSongs = [self.playlists filteredArrayUsingPredicate:combined];


    for (iTunesTrack * track in familiarSongs) {
        track.rating = 60;
    }
    

    
}


- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {

    return YES;
}


@end