//
//  TenTwentyFilter.h
//  TenTwenty
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import "StereotaxCoord.h"

@interface TenTwentyFilter : PluginFilter {
    BOOL                    foundNasion,foundInion;
    float                   minScalpValue,maxSkullValue;
    StereotaxCoord          *nasion,*inion;
    NSMutableDictionary     *orientation,*direction;
    
    DCMPix                  *midlineSlice;
}

- (long) filterImage:(NSString*) menuName;


- (void) findUserInput;
- (void) getROI: (ROI *)    thisROI 
        fromPix: (DCMPix *) thisPix 
       toCoords: (double *) location;
- (void) computeOrientation;
- (void) traceSkull;
- (NSPoint) lowerElectrode: (ROI *) thisROI inSlice: (DCMPix *) thisSlice;

@end
