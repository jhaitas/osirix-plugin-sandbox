//
//  ResliceController.m
//  TenTwenty
//
//  Created by John Haitas on 12/14/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "ResliceController.h"

@implementation ResliceController

- (id) initWithFactor: (float) theFactor
{
    if (self = [super init]) {
        factor = theFactor;
    } else {
        NSLog(@"failed to initialize ResliceController");
    }

    return self;
}

- (void) planeInView: (MPRDCMView *) theView
          withVertex: (Point3D *) vertexPt
          withPoint1: (Point3D *) point1Pt
          withPoint2: (Point3D *) point2Pt
{
    float   vertex[3],point1[3],point2[3];
    float   vector1[3],vector2[3],camPos[3],direction[3],viewUp[3];
    float   unitDirection[3],unitViewUp[3];
    Camera  *theCam;
    Point3D *camPosition,*camDirection,*camFocalPoint,*camViewUp;
    
    // get 3d positions of each point
    [self point3d: vertexPt toWorldCoords:vertex];
    [self point3d: point1Pt toWorldCoords:point1];
    [self point3d: point2Pt toWorldCoords:point2];
    
    // set camera position as average position
    camPos[0] = ( vertex[0] + point1[0] + point2[0] ) / 3.0;
    camPos[1] = ( vertex[1] + point1[1] + point2[1] ) / 3.0;
    camPos[2] = ( vertex[2] + point1[2] + point2[2] ) / 3.0;
    
    // define vectors
    vector1[0] = point1[0] - vertex[0];
    vector1[1] = point1[1] - vertex[1];
    vector1[2] = point1[2] - vertex[2];
    
    vector2[0] = point2[0] - vertex[0];
    vector2[1] = point2[1] - vertex[1];
    vector2[2] = point2[2] - vertex[2];
    
    // direction is the cross product of the two vectors
    CROSS(direction,vector1,vector2);
    
    // view up points at the vertex 'pos1' from camera position
    viewUp[0] = vertex[0] - camPos[0];
    viewUp[1] = vertex[1] - camPos[1];
    viewUp[2] = vertex[2] - camPos[2];
    
    // turn these vectors into unit vectors
    UNIT(unitDirection,direction);
    UNIT(unitViewUp,viewUp);
    
    // modify the camera
    theCam = theView.camera;
    
    camPosition     = [Point3D pointWithX:camPos[0]
                                        y:camPos[1]
                                        z:camPos[2] ];
    
    camViewUp       = [Point3D pointWithX:unitViewUp[0]
                                        y:unitViewUp[1]
                                        z:unitViewUp[2] ];
    
    camDirection    = [Point3D pointWithX:unitDirection[0]
                                        y:unitDirection[1]
                                        z:unitDirection[2]  ];
    
    camFocalPoint   = [[Point3D alloc] initWithPoint3D:camPosition];
    [camFocalPoint add:camDirection];
    
    theCam.position     = camPosition;
    theCam.focalPoint   = camFocalPoint;
    theCam.viewUp       = camViewUp;
    
    theView.camera = theCam;
    
    [theView restoreCamera];
    
    [theView.windowController updateViewsAccordingToFrame:theView];
}

- (Point3D *) directionOfCamera: (Camera *) cam
{
    Point3D *direction;
    
    // compute direction of projection vector
    direction   = [[[Point3D alloc] initWithPoint3D:cam.focalPoint] autorelease];
    [direction subtract:cam.position];
    
    return direction;
}

- (Point3D *) unitVectorFromVector: (Point3D *) vector
{
    double vec[3],unitVec[3];
    
    vec[0] = vector.x;
    vec[1] = vector.y;
    vec[2] = vector.z;
    
    UNIT(unitVec,vec);
    
    return [Point3D pointWithX:(float)unitVec[0] y:(float)unitVec[1] z:(float)unitVec[2]];
}

- (void) point3d: (Point3D *) point toWorldCoords: (float *) worldCoords
{
    worldCoords[0] = point.x * factor;
    worldCoords[1] = point.y * factor;
    worldCoords[2] = point.z * factor;
}

@end
