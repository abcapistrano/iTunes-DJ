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

- (id)init
{
    self = [super init];
    if (self) {


        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

        [nc addObserver:self selector:@selector(do) name:NSApplicationDidBecomeActiveNotification object:NSApp];
        [nc addObserver:self selector:@selector(do) name:NSApplicationDidFinishLaunchingNotification object:NSApp];


    }
    return self;
}

- (void) dealloc {

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];


}

- (void) do {


    [[NSProcessInfo processInfo] disableAutomaticTermination:@"Working"];

    self.iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.itunes"];

    iTunesUserPlaylist *playlistOfTheDay = self.playlistOfTheDay;



    iTunesPlaylist *currentPlaylist = (iTunesUserPlaylist*)self.iTunes.currentPlaylist;
    if ([playlistOfTheDay.persistentID isEqualToString:currentPlaylist.persistentID]) {


        iTunesEPlS playerState = self.iTunes.playerState;
        if (playerState == iTunesEPlSPaused || playerState == iTunesEPlSStopped) {
            [self.iTunes playpause];

        }

    } else {

        [playlistOfTheDay playOnce:YES];

    }



    
    [self showNotification];
    [self markFamiliarSongs];
    [self removeAlbumRatings];



    //sync ipod

    [self syncIpod];


    [[NSProcessInfo processInfo] enableAutomaticTermination:@"Working"];

}



- (iTunesUserPlaylist *) playlistOfTheDay {

    NSInteger dayofYear = [[NSCalendar currentCalendar] ordinalityOfUnit:NSDayCalendarUnit inUnit:NSYearCalendarUnit forDate:[NSDate date]];
    iTunesUserPlaylist *chosenPlaylist;
    self.playlists = [[[self.iTunes sources] objectWithName:@"Library"] userPlaylists];

    if (dayofYear % 2 == 1) {

        //play #Fresh

        NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@", @"#Fresh"];
        
        NSArray *results = [self.playlists filteredArrayUsingPredicate:pred];
        chosenPlaylist = results[0];

    } else {


        /* Set a new playlist of the day when:
         - the lastDate is stale
         - the lastDate is nil
         */

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        NSDate *lastPlaylistSettingDate = [userDefaults objectForKey:LAST_PLAYLIST_SETTING_DATE_KEY];
        NSString *playlistOfTheDayID;

        if (lastPlaylistSettingDate == nil || ![lastPlaylistSettingDate isSameDayAsDate:[NSDate date]]) {


            NSMutableArray *specialPlaylistsIDs = [[userDefaults arrayForKey:SPECIAL_PLAYLISTS_IDS_KEY] mutableCopy];
            if (specialPlaylistsIDs == nil || specialPlaylistsIDs.count == 0 ) {


                specialPlaylistsIDs = [NSMutableArray array];

                for (iTunesUserPlaylist *p in self.playlists) {

                    if ([p.name hasPrefix:@"#"] && ![p.name isEqualToString:@"#Fresh"]) {

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
        chosenPlaylist = results[0];


        
    }

    return chosenPlaylist;
    
}



- (void) showNotification {
    NSUserNotification *note = [NSUserNotification new];
    note.title = @"iTunes DJ";
    note.informativeText = [NSString stringWithFormat:@"Playlist \"%@\" is playing.", self.playlistOfTheDay.name];

    NSUserNotificationCenter *nc = [NSUserNotificationCenter defaultUserNotificationCenter];
    [nc removeAllDeliveredNotifications];
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


    self.allTracks = [[self.playlists objectWithName:@"Music"] fileTracks];
    NSArray* familiarSongs = [self.allTracks filteredArrayUsingPredicate:combined];


    for (iTunesTrack * track in familiarSongs) {
        track.rating = 60;
    }
    

    
}

- (void)removeAlbumRatings {

    NSPredicate * rating = [NSPredicate predicateWithFormat:@"albumRating> 0"];
    SBElementArray *copy =  [self.allTracks copy];
    [copy filterUsingPredicate:rating];

    [copy arrayByApplyingSelector:@selector(setAlbumRating:) withObject:nil];


}


- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {

    return YES;
}


@end