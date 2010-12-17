//
//  TraceController.h
//  TenTwenty
//
//  Created by John Haitas on 12/16/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"
#import "MPRHeaders.h"

@class TenTwentyController;

#define PI 3.14159265358979

#define MAG(v1) sqrt(v1[0]*v1[0]+v1[1]*v1[1]+v1[2]*v1[2]);

#define UNIT(dest,v1) \
dest[0]=v1[0]/MAG(v1); \
dest[1]=v1[1]/MAG(v1); \
dest[2]=v1[2]/MAG(v1);

@interface TraceController : NSObject {
    TenTwentyController *owner;
    MPRDCMView          *view;
    float               minScalpValue,maxSkullValue;
}

- (void) prepareWithTenTwenty: (TenTwentyController *) tenTwenty
                     minScalp: (float) minScalp
                     maxSkull: (float) maxSkull;

- (ROI *) skullTraceFromPtA: (Point3D *) pointAPt
                   toPointB: (Point3D *) pointBPt
                 withVertex: (Point3D *) vertexPt;

- (void) findSkullInPix: (DCMPix *) thePix
           fromPosition: (float [3]) thePos
            inDirection: (float [3]) theDir
             toPosition: (float [3]) finalPos;

- (BOOL) isPoint: (NSPoint) thePoint onSlice: (DCMPix *) thisPix;

- (void) point3d: (Point3D *) point toDicomCoords: (float [3]) dicomCoords;

@end
