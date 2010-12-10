//
//  MPRInspectorController.m
//  MPRInspector
//
//  Created by John Haitas on 11/1/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "MPRInspectorController.h"

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

#define IBox(x) [NSNumber numberWithInt:x]

@implementation MPRInspectorController

- (id) init
{
    if (self = [super init]) {
        [NSBundle loadNibNamed:@"MprInspectorHUD" owner:self];
        [rotationTheta setFloatValue:90.0];
        [secondsPerROI setDoubleValue:5];
        runningViewTest = NO;
        [viewEachROI setTitle:@"Start View Each ROI"];
    }
    return self;
}

- (id) initWithOwner:(id *) theOwner
{
    [self init];
    
    [self setOwner:theOwner];
    
    [self openMprViewer];    
    return self;
}

- (void) setOwner:(id *) theOwner
{
    owner = theOwner;
    viewerController = [owner valueForKey:@"viewerController"];
}

- (void) openMprViewer
{
    mprViewer = [viewerController openMPRViewer];
    [viewerController place3DViewerWindow:(NSWindowController *)mprViewer];
    [mprViewer showWindow:self];
    [[mprViewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[mprViewer window] title], [[viewerController window] title]]];
    
    
    vrController            = [mprViewer valueForKey:@"hiddenVRController"];
    vrView                  = [mprViewer valueForKey:@"hiddenVRView"];
    roi2DPointsArray        = vrController.roi2DPointsArray;
    point3DPositionsArray   = [vrView valueForKey:@"point3DPositionsArray"];
    
    currentROI = [roi2DPointsArray objectAtIndex:0];
}

- (IBAction) printCameraInfo: (id) sender
{
    NSLog(@"======================================\nCamera 1\n%@",mprViewer.mprView1.camera);
    NSLog(@"======================================\nCamera 2\n%@",mprViewer.mprView2.camera);
    NSLog(@"======================================\nCamera 3\n%@",mprViewer.mprView3.camera);
}

- (IBAction) printROICoordList: (id) sender
{
    int             i;
    float           x,y,z;
    float           pos[3];
    NSArray         *x2DPointsArray,*y2DPointsArray,*z2DPointsArray;
    
    
    // DICOM Coordinates
    x2DPointsArray              = [vrController valueForKey:@"x2DPointsArray"];
    y2DPointsArray              = [vrController valueForKey:@"y2DPointsArray"];
    z2DPointsArray              = [vrController valueForKey:@"z2DPointsArray"];
    for (i = 0; i < [roi2DPointsArray count]; i++) {
        x = [[x2DPointsArray objectAtIndex:i] floatValue];
        y = [[y2DPointsArray objectAtIndex:i] floatValue];
        z = [[z2DPointsArray objectAtIndex:i] floatValue];
        NSLog(@"%d x,y,z = %f,%f,%f\n",i,x,y,z);
    }
    
    // Volume world coordinates
    for (i = 0; i < [point3DPositionsArray count]; i++) {
        [[point3DPositionsArray objectAtIndex:i] getValue:pos];
        NSLog(@"%d x,y,z = %f,%f,%f\n",i,pos[0],pos[1],pos[2]);
    }
    
}

- (IBAction) centerViewTest: (id) sender
{
    unsigned int    i,indexROI;
    float           pos[3];
    NSString        *roiName;
    ROI             *r,*thisROI;
    
    roiName                 = [NSString stringWithString:@"nasion"];
    
    r = nil;
    thisROI = nil;
    
    for (i = 0; i < [roi2DPointsArray count]; i++) {
        r = [roi2DPointsArray objectAtIndex:i];
        if ([r.name isEqualToString:roiName]) {
            thisROI = r;
            indexROI = i;
        }
    }
             
    if (thisROI == nil) {
        NSLog(@"Failed to find ROI named %@.\n",roiName);
        return;
    }
    
    // we found the ROI we're interested in ...
    // ... get the 3D position
    [[point3DPositionsArray objectAtIndex:indexROI] getValue:pos];
    
    
    [self centerView:mprViewer.mprView1 onPt3D:pos];
}

- (IBAction) rotationTest: (id) sender
{
    // rotate view 1 by user defined theta
    [self rotateView:mprViewer.mprView1 degrees:[rotationTheta floatValue]];
}

- (IBAction) viewEachROI: (id) sender
{
    if (runningViewTest) {
        [centerTimer invalidate];
        [rotationTimer invalidate];
        runningViewTest = NO;
        [viewEachROI setTitle:@"Start View Each ROI"];
        return;
    }
    
    // start a timer to view next ROI every 2 seconds
    centerTimer = [NSTimer scheduledTimerWithTimeInterval:[secondsPerROI doubleValue]
                                                   target:self
                                                 selector:@selector(centerOnEachROI:)
                                                 userInfo:nil
                                                  repeats:YES];
    
    
    
    // start a timer to view next ROI every 2 seconds
    rotationTimer = [NSTimer scheduledTimerWithTimeInterval:[secondsPerROI doubleValue]/360.0
                                                     target:self
                                                   selector:@selector(rotateViewInc:)
                                                   userInfo:nil
                                                    repeats:YES];
    
    [viewEachROI setTitle:@"Stop View Each ROI"];
    
    runningViewTest = YES;
}

- (IBAction) view2RoiTest: (id) sender
{
    int         i,indexROI1,indexROI2;
    float       pos1[3],pos2[3];
    ROI         *r,*roi1,*roi2;
    NSString    *roiName1,*roiName2;
    
    roiName1 = [NSString stringWithString:@"Oz"];
    roiName2 = [NSString stringWithString:@"T4"];
    
    
    r = nil;
    roi1 = nil;
    roi2 = nil;
    
    for (i = 0; i < [roi2DPointsArray count]; i++) {
        r = [roi2DPointsArray objectAtIndex:i];
        if ([r.name isEqualToString:roiName1]) {
            roi1 = r;
            indexROI1 = i;
        }
        if ([r.name isEqualToString:roiName2]) {
            roi2 = r;
            indexROI2 = i;
        }
    }
    
    if (roi1 == nil) {
        NSLog(@"Failed to find ROI named %@.\n",roiName1);
        return;
    }
    
    if (roi2 == nil) {
        NSLog(@"Failed to find ROI named %@.\n",roiName2);
        return;
    }
    
    
    [[point3DPositionsArray objectAtIndex:indexROI1] getValue:pos1];
    [[point3DPositionsArray objectAtIndex:indexROI2] getValue:pos2];
    
    [self view: mprViewer.mprView1 
           ptA:[Point3D pointWithX:pos1[0] y:pos1[1] z:pos1[2]]
           ptB:[Point3D pointWithX:pos2[0] y:pos2[1] z:pos2[2]] ];
}

- (void) centerOnEachROI: (NSTimer *) theTimer
{
    unsigned int    indexROI;
    float           pos[3];    
    
    if (currentROI == nil) {
        currentROI = [roi2DPointsArray lastObject];
    }
    
    indexROI = [roi2DPointsArray indexOfObject:currentROI] + 1;
    
    if (indexROI == [roi2DPointsArray count]) {
        indexROI = 0;
    }
    
    currentROI = [roi2DPointsArray objectAtIndex:indexROI];
    
    [[point3DPositionsArray objectAtIndex:indexROI] getValue:pos];
    
    [self centerView:mprViewer.mprView1 onPt3D:pos];
}

- (void) rotateViewInc: (NSTimer *) theTimer
{
    [self rotateView:mprViewer.mprView2 degrees:1.];
}

- (void) centerView: (MPRDCMView *) theView 
             onPt3D: (float *) pt3D
{
    Point3D *direction,*newFocal,*newPosition;
    
    // compute direction of projection vector
    direction = [self directionOfCamera:theView.camera];
    
    newPosition = [Point3D pointWithX:pt3D[0] y:pt3D[1] z:pt3D[2]];
    newFocal    = [[[Point3D alloc] initWithPoint3D:newPosition] autorelease];
    
    [newFocal add:direction];
    
    [theView.camera.focalPoint setPoint3D:newFocal];
    [theView.camera.position setPoint3D:newPosition];
    
    [theView restoreCamera];
    
    [theView.windowController updateViewsAccordingToFrame:theView];
    
    [direction release];
}

- (void) rotateView: (MPRDCMView *) theView
            degrees: (float) theta
{
    Point3D *direction,*newViewUp;
    
    // compute direction of projection vector
    direction = [self directionOfCamera:theView.camera];
    
    // IMPORTANT direction vector must be a unit vector
    newViewUp = [self rotateVector:theView.camera.viewUp aroundAxis:[self unitVectorFromVector:direction] byTheta:theta];
    
    theView.camera.viewUp = newViewUp;
    
    [theView restoreCamera];
    
    [theView.windowController updateViewsAccordingToFrame:theView];
    
}

- (void) view: (MPRDCMView *) theView
          ptA: (Point3D *) ptA
          ptB: (Point3D *) ptB
{
    float pos[3],v1[3];
    
    int             opposite,adjacent;
    float           theta;
    Point3D         *direction;
    NSNumber        *xAxis,*yAxis,*zAxis;
    NSMutableArray  *axes;
    
    xAxis = IBox(0);
    yAxis = IBox(1);
    zAxis = IBox(2);
    axes = [NSMutableArray arrayWithObjects:xAxis,yAxis,zAxis,nil];
    
    direction = [self unitVectorFromVector:[self directionOfCamera:theView.camera]];
    
    
    if (abs(theView.camera.viewUp.x) > 0) {
        NSLog(@"X axis is up\n");
        adjacent = [xAxis intValue];
        [axes removeObjectIdenticalTo:xAxis];
    }
    if (abs(theView.camera.viewUp.y) > 0) {
        NSLog(@"Y axis is up\n");
        adjacent = [yAxis intValue];
        [axes removeObjectIdenticalTo:yAxis];
    }
    if (abs(theView.camera.viewUp.z) > 0) {
        NSLog(@"Z axis is up\n");
        adjacent = [zAxis intValue];
        [axes removeObjectIdenticalTo:zAxis];
    }
    
    if (abs(direction.x) > 0) {
        NSLog(@"directed on X axis\n");
        [axes removeObjectIdenticalTo:xAxis];
    }
    if (abs(direction.y) > 0) {
        NSLog(@"directed on Y axis\n");
        [axes removeObjectIdenticalTo:yAxis];
    }
    if (abs(direction.z) > 0) {
        NSLog(@"directed on Z axis\n");
        [axes removeObjectIdenticalTo:zAxis];
    }
    
    if ([axes count] == 1) {
        opposite = [[axes objectAtIndex:0] intValue];
    } else {
        NSLog(@"Logic error!");
    }

    
    pos[0] = ptA.x;
    pos[1] = ptA.y;
    pos[2] = ptA.z;
    
    v1[0] = ptB.x - pos[0];
    v1[1] = ptB.y - pos[1];
    v1[2] = ptB.z - pos[2];
    
    theta = atan(v1[opposite]/v1[adjacent]) * rad2deg;

    NSLog(@"theta = %f\n",theta);
    
    [self centerView: theView onPt3D: pos];
    [self rotateView:theView degrees:theta]; 
}

- (Point3D *) rotateVector: (Point3D *) vectorOne
                aroundAxis: (Point3D *) axis
                   byTheta: (float) thetaDeg
{
    // rotate the point (x,y,z) theta degrees around the vector (u,v,w)
    double u,v,w,x,y,z,theX,theY,theZ,thetaRad;
    double theVec[3],theAxis[3],theDot,cosTheta,sinTheta;
    
    
    // convert degrees to radians
    thetaRad = thetaDeg * deg2rad;
    
    cosTheta = cos(thetaRad);
    sinTheta = sin(thetaRad);
    
    x = vectorOne.x;
    y = vectorOne.y;
    z = vectorOne.z;
    
    u = axis.x;
    v = axis.y;
    w = axis.z;
    
    theVec[0] = x;
    theVec[1] = y;
    theVec[2] = z;
    
    theAxis[0] = u;
    theAxis[1] = v;
    theAxis[2] = w;
    
    theDot = DOT(theVec,theAxis);
    
    theX = (u * theDot) + (x * (v*v + w*w) - u * (v*y + w*z)) * cosTheta + (-(w*y) + v*z) * sinTheta;
    theY = (v * theDot) + (y * (u*u + w*w) - v * (u*x + w*z)) * cosTheta + (  w*x  - u*z) * sinTheta;
    theZ = (w * theDot) + (z * (u*u + v*v) - w * (u*x + v*y)) * cosTheta + (-(v*x) + u*y) * sinTheta;
    
    return [Point3D pointWithX:(float)theX y:(float)theY z:(float)theZ];            
}

- (Point3D *) directionOfCamera: (Camera *) cam
{
    Point3D *direction;
    
    // compute direction of projection vector
    direction   = [[Point3D alloc] initWithPoint3D:cam.focalPoint];
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

@end
