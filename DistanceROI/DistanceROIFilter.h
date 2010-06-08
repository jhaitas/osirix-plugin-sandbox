//
//  DistanceROIFilter.h
//  DistanceROI
//
//  Copyright (c) 2010 John Haitas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface DistanceROIFilter : PluginFilter {
	NSMutableArray *allROIs;
}

- (void) getAllROIs;
- (long) filterImage:(NSString*) menuName;

@end
