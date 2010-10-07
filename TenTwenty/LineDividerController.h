//
//  LineDividerController.h
//  TenTwenty
//
//  Created by John Haitas on 10/7/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"

#define FBOX(x) [NSNumber numberWithFloat:x]

@interface LineDividerController : NSObject {
    ViewerController    *viewerController;
    
	float			scaleValue;
	NSArray			*tenTwentyIntervals;
	NSMutableArray	*roiSelectedArray;
	NSMutableArray	*selectedOPolyRois;
	
	NSMutableArray	*currentSpline;
	NSMutableArray	*currentInterPoints;
}

- (id) init;
- (id) initWithViewerController:(ViewerController *) vc;

- (void) divideLine:(ROI *) roiOPoly;

- (void) addIntermediateROIs;
- (NSMutableArray *)computePercentLength:(ROI *)thisROI;
- (float) measureOPolyLength:(ROI *)thisROI 
            fromPointAtIndex:(long)indexPointA 
              toPointAtIndex:(long)indexPointB;
- (float) measureOPolyLength:(ROI *)thisROI;
- (float) accumulatedIntervalAtIndex:(int) index;

@end
