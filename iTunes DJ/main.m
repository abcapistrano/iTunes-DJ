//
//  main.m
//  iTunes DJ
//
//  Created by Earl on 7/30/12.
//  Copyright (c) 2012 Earl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DJAppDelegate.h"

int main(int argc, char *argv[])
{

    NSApplication * application = [NSApplication sharedApplication];
    DJAppDelegate *delegate = [[DJAppDelegate alloc] init];
    [application setDelegate:delegate];
    [application run];

    return EXIT_SUCCESS;



}
