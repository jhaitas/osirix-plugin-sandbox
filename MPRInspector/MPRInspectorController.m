//
//  MPRInspectorController.m
//  MPRInspector
//
//  Created by John Haitas on 11/1/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "MPRInspectorController.h"

static double deg2rad = 3.14159265358979/180.0;

@implementation MPRInspectorController

- (id) init
{
    if (self = [super init]) {
        [NSBundle loadNibNamed:@"MprInspectorHUD" owner:self];
        [rotationTheta setFloatValue:90.0];
        [secondsPerROI setDoubleValue:5];
        runningViewTest = NO;
        [viewEachROI setTitle:@"Start View Each ROI"];
        currentROI = nil;
    }
    return self;
}

- (id) initWithOwner:(id *) theOwner
{
    [self init];
    owner = theOwner;
    viewerController = [owner valueForKey:@"viewerController"];
    return self;
}

- (IBAction) openMprViewer: (id) sender
{    
    mprViewer = [viewerController openMPRViewer];
    [viewerController place3DViewerWindow:(NSWindowController *)mprViewer];
    [mprViewer showWindow:self];
    [[mprViewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[mprViewer window] title], [[viewerController window] title]]];
    
    
    vrController            = [mprViewer valueForKey:@"hiddenVRController"];
    vrView                  = [mprViewer valueForKey:@"hiddenVRView"];
    roi2DPointsArray        = vrController.roi2DPointsArray;
    point3DPositionsArray   = [vrView valueForKey:@"point3DPositionsArray"];
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
    // rotate view 2 by user defined theta
    [self rotateView:mprViewer.mprView2 degrees:[rotationTheta floatValue]];
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
    direction   = [[Point3D alloc] initWithPoint3D:theView.camera.focalPoint];
    [direction subtract:theView.camera.position];
    
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
    direction   = [[Point3D alloc] initWithPoint3D:theView.camera.focalPoint];
    [direction subtract:theView.camera.position];
    
    // IMPORTANT vectors must be normalized
    direction = [self normalizePt:direction];
    
    newViewUp = [self rotateVector:theView.camera.viewUp aroundVector:[self normalizePt:direction] byTheta:theta];
    
    theView.camera.viewUp = newViewUp;
    
    [theView restoreCamera];
    
    [theView.windowController updateViewsAccordingToFrame:theView];
    
}

- (Point3D *) rotateVector: (Point3D *) vectorOne
              aroundVector: (Point3D *) axis
                   byTheta: (float) thetaDeg
{
    // rotate the point (x,y,z) around the vector (u,v,w)
    double u,v,w,x,y,z,theX,theY,theZ,thetaRad;
    
    // convert degrees to radians
    thetaRad = thetaDeg * deg2rad;
    
    x = vectorOne.x;
    y = vectorOne.y;
    z = vectorOne.z;
    
    u = axis.x;
    v = axis.y;
    w = axis.z;
    
    theX = u * (u*x + v*y + w*z) + (x * (v*v + w*w) - u * (v*y + w*z)) * cos(thetaRad) + (-(w*y) + v*z) * sin(thetaRad);
    theY = v * (u*x + v*y + w*z) + (y * (u*u + w*w) - v * (u*x + w*z)) * cos(thetaRad) + (  w*x  - u*z) * sin(thetaRad);
    theZ = w * (u*x + v*y + w*z) + (z * (u*u + v*v) - w * (u*x + v*y)) * cos(thetaRad) + (-(v*x) + u*y) * sin(thetaRad);
    
    return [Point3D pointWithX:(float)theX y:(float)theY z:(float)theZ];            
}

- (Point3D *) normalizePt: (Point3D *) thePt
{
    double x,y,z,mag;
    
    x = thePt.x;
    y = thePt.y;
    z = thePt.z;
    
    mag = sqrt(x*x+y*y+z*z);
    
    return [Point3D pointWithX:(float)(x/mag) y:(float)(y/mag) z:(float)(z/mag)];
}

@end
