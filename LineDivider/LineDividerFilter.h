//
//  LineDividerFilter.h
//  LineDivider
//
//  Copyright (c) 2010 John Haitas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

#define FBOX(x) [NSNumber numberWithFloat:x]

@interface LineDividerFilter : PluginFilter {
	float			scaleValue;
	NSArray			*tenTwentyIntervals;
	NSMutableArray	*roiSelectedArray;
	NSMutableArray	*selectedOPolyRois;
	
	NSMutableArray	*currentSpline;
	NSMutableArray	*currentInterPoints;
}

- (long)filterImage:(NSString*)menuName;
- (void)findSelectedROIs;
- (void)findLineROIs;
- (void)partitionAllOpenPolyROIs;
- (void)addIntermediateROIs;
- (NSMutableArray *)computePercentLength:(ROI *)thisROI;
- (float)measureOPolyLength:(ROI *)thisROI 
		   fromPointAtIndex:(long)indexPointA 
			 toPointAtIndex:(long)indexPointB;
- (float)measureOPolyLength:(ROI *)thisROI;
- (float)accumulatedIntervalAtIndex:(int) index;

@end
