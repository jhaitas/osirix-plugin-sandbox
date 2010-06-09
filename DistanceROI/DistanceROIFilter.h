//
//  DistanceROIFilter.h
//  DistanceROI
//
//  Copyright (c) 2010 John Haitas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import "ROImm.h"

@interface DistanceROIFilter : PluginFilter {
	NSMutableArray *allROIs;
}

- (void) getAllROIs;
- (void) printAllDistances;
- (long) filterImage:(NSString*) menuName;

@end
