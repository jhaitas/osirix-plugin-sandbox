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

#define PI 3.14159265358979

#define MAG(v1) sqrt(v1[0]*v1[0]+v1[1]*v1[1]+v1[2]*v1[2]);

#define UNIT(dest,v1) \
dest[0]=v1[0]/MAG(v1); \
dest[1]=v1[1]/MAG(v1); \
dest[2]=v1[2]/MAG(v1);

@interface TraceController : NSObject {
    DCMPix          *pix;
    float           minScalp,maxSkull;
    ROI             *trace;
    NSArray         *searchPaths;
}

@property (readonly)    ROI     *trace;
@property (readonly)    NSArray *searchPaths;
@property (assign)      float   minScalp,maxSkull;

- (id) initWithPix: (DCMPix *)  thePix
          minScalp: (float)     theMinScalp
          maxSkull: (float)     theMaxSkull;

- (void) traceFromPtA: (Point3D *) pointAPt
             toPointB: (Point3D *) pointBPt
           withVertex: (Point3D *) vertexPt;

- (NSPoint) findFromPosition: (float [3]) position
                 inDirection: (float [3]) direction;

- (BOOL) isPointOnPix: (NSPoint) point;

- (void) point3d: (Point3D *) point
   toDicomCoords: (float [3]) dicomCoords;

@end
