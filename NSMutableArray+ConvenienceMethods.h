//
//  NSMutableArray+ConvenienceMethods.h
//  iTunes DJ
//
//  Created by Earl on 8/18/12.
//  Copyright (c) 2012 Earl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (ConvenienceMethods)
- (NSArray *) grab : (NSInteger) sampleSize ;
- (void) randomize;
@end