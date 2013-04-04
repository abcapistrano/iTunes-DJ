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
#import "NSDate+MoreDates.h"
#import "NSURL+FileManagement.h"
#import "MTRandom.h"

NSString * const SPECIAL_PLAYLISTS_IDS_KEY = @"specialPlaylistsIDs";
NSString * const PLAYLIST_OF_THE_DAY_KEY = @"playlistOfTheDay";
NSString * const LAST_PLAYLIST_SETTING_DATE_KEY = @"lastPlaylistSettingDate";


@implementation DJAppDelegate

- (id)init
{
    self = [super init];
    if (self) {

        _iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.itunes"];
        _playlists = [[[_iTunes sources] objectWithName:@"Library"] userPlaylists];
        _allTracks = [[_playlists objectWithName:@"Music"] fileTracks];

    }
    return self;
}


- (void) applicationDidFinishLaunching:(NSNotification *)notification {


    iTunesUserPlaylist *playlistOfTheDay = self.playlistOfTheDay;

    if ([playlistOfTheDay.name isEqualToString:@"#Fresh"]) {

        NSUInteger count = playlistOfTheDay.fileTracks.count;
        if (count == 0) {
            [self importNewAlbum];
        }

    }

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
    [self removeComputedRatings];
    [self markFamiliarSongs];
    [self syncIpod];
    
    [NSApp terminate:self];




}

- (void) importNewAlbum {
    NSURL* newAlbumsDir = [NSURL fileURLWithPath:@"/Users/earltagra/Music/New Albums"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isDirectory == YES && files.@count > 1"];
    NSArray *sortedAlbums = [[newAlbumsDir.files filteredArrayUsingPredicate:pred] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastPathComponent" ascending:YES]]];
    
    NSURL* chosenDirectory = sortedAlbums[0];

    [chosenDirectory.files enumerateObjectsUsingBlock:^(NSURL* file, NSUInteger idx, BOOL *stop) {

        //goal: delete files with *.m3u extension
        NSString *extension = [file pathExtension];
        if ([extension isEqualToString:@"m3u"]) {

            [file trashFile];

        }




    }];


    iTunesUserPlaylist *music = [self.playlists objectWithName:@"Music"];
    NSArray *tracksAdded = (NSArray *)[self.iTunes add:@[chosenDirectory] to:music];

    void(^rateTracks)(iTunesFileTrack *, NSUInteger, BOOL *) = ^(iTunesFileTrack * track, NSUInteger idx, BOOL* stop) {

        track.rating = 40;

    };

    [tracksAdded enumerateObjectsUsingBlock:rateTracks];

    NSUInteger maxFreshPlaylistCount = 100;
    NSUInteger runningCount = tracksAdded.count;

    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"dateAdded" ascending:YES];


    iTunesUserPlaylist *playlist2011 = [self.playlists objectWithName:@"2011"];
    NSUInteger count2011 = playlist2011.fileTracks.count;
    if (count2011 == 0) {
        [playlist2011 delete];
    } else {


        NSArray *sorted = [playlist2011.fileTracks.get sortedArrayUsingDescriptors:@[sd]];
        NSUInteger max = ceil((maxFreshPlaylistCount - runningCount) / 2);
        runningCount += max;
        NSArray *sub = [sorted subarrayWithRange:NSMakeRange(0, MIN(max, sorted.count) )];
        [sub enumerateObjectsUsingBlock:rateTracks];

    }

    iTunesUserPlaylist *playlist2012 = [self.playlists objectWithName:@"2012"];
    NSUInteger count2012 = playlist2012.fileTracks.count;
    if (count2012 == 0) {
        [playlist2012 delete];
    } else {


        NSArray *sorted = [playlist2012.fileTracks.get sortedArrayUsingDescriptors:@[sd]];
        NSUInteger max = maxFreshPlaylistCount - runningCount;
        runningCount += max;
        NSArray *sub = [sorted subarrayWithRange:NSMakeRange(0, MIN(max, sorted.count) )];
        [sub enumerateObjectsUsingBlock:rateTracks];

    }

    // add songs from the forgotten

    //            NSPredicate * predicate = [NSPredicate predicateWithFormat:@"rating >= 60"];
    //            NSSortDescriptor *sd2 = [NSSortDescriptor sortDescriptorWithKey:@"playedDate" ascending:YES];
    //            NSArray* filtered = [self.allTracks filteredArrayUsingPredicate:predicate];
    //            NSArray* sorted = [filtered sortedArrayUsingDescriptors:@[sd2]];
    //            NSUInteger max = maxFreshPlaylistCount - runningCount;
    //            NSArray *sub = [sorted subarrayWithRange:NSMakeRange(0, MIN(max, sorted.count) )];
    //            [sub enumerateObjectsUsingBlock:rateTracks];



    [chosenDirectory trashFile];    
}



- (iTunesUserPlaylist *) playlistOfTheDay {

    NSInteger dayofYear = [[NSCalendar currentCalendar] ordinalityOfUnit:NSDayCalendarUnit inUnit:NSYearCalendarUnit forDate:[NSDate date]];
    iTunesUserPlaylist *chosenPlaylist;
    

  if (dayofYear % 2 == 1) {


        //play #Fresh

        NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@", @"#Fresh"];
        
        NSArray *results = [self.playlists filteredArrayUsingPredicate:pred];
        chosenPlaylist = results[0];

 
            


        }

        

    else {


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

    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"rating != 20 AND rating <= 40 AND playedCount >= 5"];
    NSArray* familiarSongs = [self.allTracks filteredArrayUsingPredicate:predicate];


    for (iTunesTrack * track in familiarSongs) {
        track.rating = 60;
    }
    

    
}

- (void)removeComputedRatings {

    NSPredicate * rating = [NSPredicate predicateWithFormat:@"albumRatingKind == %@ AND albumRating > 0", [NSAppleEventDescriptor descriptorWithEnumCode:iTunesERtKComputed]];
    SBElementArray *copy =  [self.allTracks copy];
    [copy filterUsingPredicate:rating];
    NSArray * results = [copy get];
    [results enumerateObjectsUsingBlock:^(iTunesFileTrack *track, NSUInteger idx, BOOL *stop) {
        track.albumRating = 1;

    }];

    rating = [NSPredicate predicateWithFormat:@"ratingKind == %@ AND rating > 0", [NSAppleEventDescriptor descriptorWithEnumCode:iTunesERtKComputed]];
    copy =  [self.allTracks copy];
    [copy filterUsingPredicate:rating];
    results = [copy get];
    [results enumerateObjectsUsingBlock:^(iTunesFileTrack *track, NSUInteger idx, BOOL *stop) {
        track.rating = 1;

    }];
    


}


- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {

    return YES;
}


@end