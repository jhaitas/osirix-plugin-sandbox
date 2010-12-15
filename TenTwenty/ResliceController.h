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



#define PRECISION 0.0001

#define PI 3.14159265358979

static float deg2rad = PI/180.0;
static float rad2deg = 180.0/PI;


#define MAG(v1) sqrt(v1[0]*v1[0]+v1[1]*v1[1]+v1[2]*v1[2]);

static float unitMag;
#define UNIT(dest,v1) \
unitMag = MAG(v1) \
dest[0]=v1[0]/unitMag; \
dest[1]=v1[1]/unitMag; \
dest[2]=v1[2]/unitMag;

#define DOT(v1,v2) v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2];

#define CROSS(dest,v1,v2) \
dest[0]=v1[1]*v2[2]-v1[2]*v2[1]; \
dest[1]=v1[2]*v2[0]-v1[0]*v2[2]; \
dest[2]=v1[0]*v2[1]-v1[1]*v2[0];

@class TenTwentyController;


@interface ResliceController : NSObject {
    id owner;
    
    ViewerController    *viewerController;
    MPRController       *mprViewer;
    
    VRController        *vrController;
    VRView              *vrView;
    
    NSArray             *roi2DPointsArray,*point3DPositionsArray;
}


@property (assign) MPRController *mprViewer;

- (id) init;
- (id) initWithOwner:(id *) theOwner;
- (void) setOwner:(id *) theOwner;

- (void) openMprViewer;
- (void) closeMprViewer;

- (void) planeInView: (MPRDCMView *) theView
          WithVertex: (NSString *) vertexName
          withPoint1: (NSString *) point1Name
          withPoint2: (NSString *) point2Name;

- (ROI *) get2dRoiNamed: (NSString *) roiName
               fromView: (MPRDCMView *) theView;
- (ROI *) getWorldRoiNamed: (NSString *) roiName;
- (void) get3dPosition: (float [3])pos ofRoi: (ROI *) theROI;

- (Point3D *) directionOfCamera: (Camera *) cam;
- (Point3D *) unitVectorFromVector: (Point3D *) vector;

@end