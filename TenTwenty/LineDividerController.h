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
    DCMPix          *thePix;
    
	float			scaleValue;
    NSDictionary    *lineIntervalsDict;
	
	NSMutableArray      *currentSpline;
	NSMutableDictionary *currentInterPoints;
}

- (id) init;
- (id) initWithPix: (DCMPix *) pix;

- (void) setDistanceDict: (NSDictionary *) inputDict;

- (void) divideLine:(ROI *) roiOPoly;

- (NSArray *) intermediateROIs;

- (NSMutableArray *) computePercentLength:(ROI *)thisROI;

- (float) measureOPolyLength: (ROI *)   roi 
            fromPointAtIndex: (long)    indexPointA 
              toPointAtIndex: (long)    indexPointB;

- (float) measureOPolyLength: (ROI *) roi;

@end
