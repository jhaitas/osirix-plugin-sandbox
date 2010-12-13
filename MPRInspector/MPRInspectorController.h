//
//  MPRInspectorController.h
//  MPRInspector
//
//  Created by John Haitas on 11/1/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"
#import "MPRHeaders.h"


@interface MPRInspectorController : NSObject {
    id owner;
    
    ViewerController    *viewerController;
    MPRController       *mprViewer;
    
    VRController        *vrController;
    VRView              *vrView;
    
    NSArray             *roi2DPointsArray,*point3DPositionsArray;
    
    ROI                 *currentROI;
    
    BOOL                runningViewTest;
    NSTimer             *centerTimer,*rotationTimer;
    
    IBOutlet NSPanel    *mprInspectorHUD;
    
    IBOutlet NSButton   *printCameraInfo;
    IBOutlet NSButton   *printROICoordList;
    IBOutlet NSButton   *centerViewTest;
    IBOutlet NSButton   *rotationTest;
    
    IBOutlet NSTextField *rotationTheta;
    
    IBOutlet NSButton   *viewEachROI;
    
    IBOutlet NSTextField *secondsPerROI;
    
    IBOutlet NSButton   *view2RoiTest;
    IBOutlet NSButton   *threeRoiPlane;
}

- (id) init;
- (id) initWithOwner:(id *) theOwner;

- (void) setOwner:(id *) theOwner;
- (void) openMprViewer;

- (IBAction) printCameraInfo: (id) sender;
- (IBAction) printROICoordList: (id) sender;
- (IBAction) centerViewTest: (id) sender;
- (IBAction) rotationTest: (id) sender;
- (IBAction) viewEachROI: (id) sender;
- (IBAction) view2RoiTest: (id) sender;
- (IBAction) threeRoiPlane: (id) sender;

- (void) centerOnEachROI: (NSTimer *) theTimer;
- (void) rotateViewInc: (NSTimer *) theTimer;

- (void) centerView: (MPRDCMView *) theView 
             onPt3D: (float *) pt3D;
- (void) rotateView: (MPRDCMView *) theView
            degrees: (float) theta;

- (void) view: (MPRDCMView *) theView
          ptA: (Point3D *) ptA
          ptB: (Point3D *) ptB;

- (Point3D *) rotateVector: (Point3D *) vectorOne
                aroundAxis: (Point3D *) axis
                   byTheta: (float) thetaDeg;

- (Point3D *) directionOfCamera: (Camera *) cam;

- (Point3D *) unitVectorFromVector: (Point3D *) vector;

@end
