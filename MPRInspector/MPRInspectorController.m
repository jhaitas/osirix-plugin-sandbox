//
//  MPRInspectorController.m
//  MPRInspector
//
//  Created by John Haitas on 11/1/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "MPRInspectorController.h"


@implementation MPRInspectorController

- (id) init
{
    if (self = [super init]) {
        [NSBundle loadNibNamed:@"MprInspectorHUD" owner:self];
        
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
    VRController    *vrController;
    NSArray         *roi2DPointsArray,*sliceNumber2DPointsArray,*x2DPointsArray,*y2DPointsArray,*z2DPointsArray;
    
    
    // VRController
    vrController                = [mprViewer valueForKey:@"hiddenVRController"];
    roi2DPointsArray            = vrController.roi2DPointsArray;
    sliceNumber2DPointsArray    = [vrController valueForKey:@"sliceNumber2DPointsArray"];
    x2DPointsArray              = [vrController valueForKey:@"x2DPointsArray"];
    y2DPointsArray              = [vrController valueForKey:@"y2DPointsArray"];
    z2DPointsArray              = [vrController valueForKey:@"z2DPointsArray"];
    
    for (i = 0; i < [roi2DPointsArray count]; i++) {
        x = [[x2DPointsArray objectAtIndex:i] floatValue];
        y = [[y2DPointsArray objectAtIndex:i] floatValue];
        z = [[z2DPointsArray objectAtIndex:i] floatValue];
        NSLog(@"%d x,y,z = %f,%f,%f\n",i,x,y,z);
    }
    
    // VRView !!! contains correct coordinates for camera!!!!
    float   pos[3];
    VRView  *vrView;
    NSArray *point3DPositionsArray;
    
    vrView                  = [mprViewer valueForKey:@"hiddenVRView"];
    point3DPositionsArray   = [vrView valueForKey:@"point3DPositionsArray"];
    
    
    for (i = 0; i < [point3DPositionsArray count]; i++) {
        [[point3DPositionsArray objectAtIndex:i] getValue:pos];
        NSLog(@"%d x,y,z = %f,%f,%f\n",i,pos[0],pos[1],pos[2]);
    }
    
}

- (IBAction) centerViewTest: (id) sender
{
    unsigned int    i,indexROI;
    float           pos[3];
    VRController    *vrController;
    VRView          *vrView;
    NSString        *roiName;
    NSArray         *roi2DPointsArray,*point3DPositionsArray;
    ROI             *r,*thisROI;
    
    roiName                 = [NSString stringWithString:@"nasion"];
    vrController            = [mprViewer valueForKey:@"hiddenVRController"];
    vrView                  = [mprViewer valueForKey:@"hiddenVRView"];
    roi2DPointsArray        = vrController.roi2DPointsArray;
    point3DPositionsArray   = [vrView valueForKey:@"point3DPositionsArray"];
    
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

- (IBAction) convertRoiCoords: (id) sender
{
    float   pt2d[3],pt3d[3];
    NSPoint roiPoint,glPoint;
    
    for (ROI *r in mprViewer.mprView1.curRoiList) {
        roiPoint = r.rect.origin;
        
        roiPoint.x *= mprViewer.mprView1.pixelSpacingX;
        roiPoint.y *= mprViewer.mprView1.pixelSpacingY;
        
        glPoint = [mprViewer.mprView1 ConvertFromNSView2GL:roiPoint];
        
        pt2d[0] = glPoint.x;
        pt2d[1] = glPoint.y;
        pt2d[2] = 0;
        
        [mprViewer.mprView1.vrView convert2DPoint:pt2d to3DPoint:pt3d];
        
        NSLog(@"%@ converts from (%.3f, %.3f) to (%.3f, %.3f)\n",r.parentROI.name,roiPoint.x,roiPoint.y,glPoint.x,glPoint.y);
        NSLog(@"%@ converts from (%.3f, %.3f, %.3f) to (%.3f, %.3f, %.3f)\n",r.parentROI.name,pt2d[0],pt2d[1],pt2d[2],pt3d[0],pt3d[1],pt3d[2]);
    }
}

- (void) centerView: (MPRDCMView *) theView 
             onPt3D: (float *) pt3D
{
    Camera  *theCamera;
    Point3D *oldFocal,*oldPosition,*direction,*newFocal,*newPosition;
    
    theCamera   = [[Camera alloc] initWithCamera:[theView camera]];
    
    oldFocal    = [[Point3D alloc] initWithPoint3D:theCamera.focalPoint];
    oldPosition = [[Point3D alloc] initWithPoint3D:theCamera.position];
    direction   = [[Point3D alloc] initWithPoint3D:oldFocal];
                  
    [direction subtract:oldPosition];
    
    newPosition = [Point3D pointWithX:pt3D[0] y:pt3D[1] z:pt3D[2]];
    newFocal    = [[Point3D alloc] initWithPoint3D:newPosition];
    
    [newFocal add:direction];
    
    [theCamera.focalPoint setPoint3D:newFocal];
    [theCamera.position setPoint3D:newPosition];
    theCamera.forceUpdate = YES;
    
    theView.camera = theCamera;
    [theView restoreCamera];
    
    [theView updateViewMPR: NO];
	[theView.windowController updateViewsAccordingToFrame:theView];
    
}

@end
