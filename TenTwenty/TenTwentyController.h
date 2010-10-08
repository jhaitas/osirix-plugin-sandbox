//
//  TenTwentyController.h
//  TenTwenty
//
//  Created by John Haitas on 10/8/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"
#import "LineDividerController.h"
#import "StereotaxCoord.h"


@interface TenTwentyController : NSObject {
    ViewerController    *viewerController;
    
    BOOL                foundNasion,foundInion;
    StereotaxCoord      *nasion,*inion;
    NSMutableDictionary *orientation,*direction;
    
    float               minScalpValue,maxSkullValue;
    
    DCMPix              *midlineSlice;
    ROI                 *midlineSkullTrace;
    
    LineDividerController *ld;
}

@property (assign) BOOL foundNasion,foundInion;

- (id) init;
- (id) initWithViewerController:(ViewerController *) vc;

- (void) findUserInput;
- (void) getROI: (ROI *)    thisROI 
        fromPix: (DCMPix *) thisPix 
       toCoords: (double *) location;

- (void) computeOrientation;
- (void) remapNasionAndInion;

- (void) placeMidlineElectrodes;
- (void) traceSkull;
- (NSPoint) lowerElectrode: (ROI *) thisROI inSlice: (DCMPix *) thisSlice;

@end
