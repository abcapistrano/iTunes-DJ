//
//  DJAppDelegate.h
//  iTunes DJ
//
//  Created by Earl on 7/30/12.
//  Copyright (c) 2012 Earl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"
#import <ScriptingBridge/ScriptingBridge.h>

@interface DJAppDelegate : NSObject  <NSApplicationDelegate, NSUserNotificationCenterDelegate>
@property (assign) IBOutlet NSWindow *window;

@end

