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

@class TenTwentyController;

#define PRECISION 0.0001

#define PI 3.14159265358979


#define MAG(v1) sqrt(v1[0]*v1[0]+v1[1]*v1[1]+v1[2]*v1[2]);

#define UNIT(dest,v1) \
dest[0]=v1[0]/MAG(v1); \
dest[1]=v1[1]/MAG(v1); \
dest[2]=v1[2]/MAG(v1);

#define DOT(v1,v2) v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2];

#define CROSS(dest,v1,v2) \
dest[0]=v1[1]*v2[2]-v1[2]*v2[1]; \
dest[1]=v1[2]*v2[0]-v1[0]*v2[2]; \
dest[2]=v1[0]*v2[1]-v1[1]*v2[0];

@interface ResliceController : NSObject {
    TenTwentyController *owner;
    
    ViewerController    *viewerController;
    MPRController       *mprViewer;
    
    VRController        *vrController;
    VRView              *vrView;
    
    NSArray             *roi2DPointsArray,*point3DPositionsArray;
    
    float factor;
}

@property (assign) MPRController *mprViewer;

- (id) init;

- (void) prepareWithTenTwenty: (TenTwentyController *) theTenTwenty;

- (void) openMprViewer;
- (void) closeMprViewer;

- (void) planeInView: (MPRDCMView *) theView
          withVertex: (Point3D *) vertexPt
          withPoint1: (Point3D *) point1Pt
          withPoint2: (Point3D *) point2Pt;

- (ROI *) get2dRoiNamed: (NSString *) roiName
               fromView: (MPRDCMView *) theView;
- (ROI *) getWorldRoiNamed: (NSString *) roiName;
- (void) get3dPosition: (float [3])pos ofRoi: (ROI *) theROI;

- (Point3D *) directionOfCamera: (Camera *) cam;
- (Point3D *) unitVectorFromVector: (Point3D *) vector;

- (void) point3d: (Point3D *) point toWorldCoords: (float *) worldCoords;

@end
