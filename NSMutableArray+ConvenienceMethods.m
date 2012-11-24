//
//  NSMutableArray+ConvenienceMethods.m
//  iTunes DJ
//
//  Created by Earl on 8/18/12.
//  Copyright (c) 2012 Earl. All rights reserved.
//

#import "NSMutableArray+ConvenienceMethods.h"

@implementation NSMutableArray (ConvenienceMethods)

// WARNING: this shuffles the array
- (NSArray *) grab : (NSInteger) sampleSize {
    
    NSInteger maxSize = [self count];
    
    if (maxSize < sampleSize) {
        sampleSize = maxSize;
    }
    
    NSRange x = NSMakeRange(0, sampleSize);
    
    [self randomize];
    
    NSArray *sample = [self subarrayWithRange:x];
    
    [self removeObjectsInRange:x];
    
    
    return sample;
    
    
}

- (void)randomize
{
    NSInteger count = [self count];
    for (NSInteger i = 0; i < count - 1; i++)
    {
        NSInteger swap = arc4random() % (count - i) + i;
        [self exchangeObjectAtIndex:swap withObjectAtIndex:i];
    }
}



@end
