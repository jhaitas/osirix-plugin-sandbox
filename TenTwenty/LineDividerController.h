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
    NSDictionary    *lineIntervalsDict;
	
	NSMutableArray      *currentSpline;
	NSMutableDictionary *currentInterPoints;
}

- (id) init;
- (id) initWithViewerController:(ViewerController *) vc;
- (void) setDistanceDict: (NSDictionary *) inputDict;

- (void) divideLine:(ROI *) roiOPoly;

- (void) addIntermediateROIs;
- (NSMutableArray *) computePercentLength:(ROI *)thisROI;
- (float) measureOPolyLength:(ROI *)thisROI 
            fromPointAtIndex:(long)indexPointA 
              toPointAtIndex:(long)indexPointB;
- (float) measureOPolyLength:(ROI *)thisROI;

@end
