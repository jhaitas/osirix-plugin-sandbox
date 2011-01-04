//
//  ResliceController.h
//  TenTwenty
//
//  Created by John Haitas on 12/14/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"
#import "MPRHeaders.h"

#define MAG(v1) sqrt(v1[0]*v1[0]+v1[1]*v1[1]+v1[2]*v1[2]);

#define UNIT(dest,v1) \
dest[0]=v1[0]/MAG(v1); \
dest[1]=v1[1]/MAG(v1); \
dest[2]=v1[2]/MAG(v1);

#define CROSS(dest,v1,v2) \
dest[0]=v1[1]*v2[2]-v1[2]*v2[1]; \
dest[1]=v1[2]*v2[0]-v1[0]*v2[2]; \
dest[2]=v1[0]*v2[1]-v1[1]*v2[0];

@interface ResliceController : NSObject {
    MPRDCMView *view;
}

- (id) initWithView: (MPRDCMView *) theView;

- (void) planeWithVertex: (Point3D *) vertexPt
              withPoint1: (Point3D *) point1Pt
              withPoint2: (Point3D *) point2Pt;

- (void) point3d: (Point3D *) point toWorldCoords: (float *) worldCoords;

@end
