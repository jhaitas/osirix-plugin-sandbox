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
    IBOutlet NSButton   *openMprViewer;
    IBOutlet NSButton   *printCameraInfo;
    IBOutlet NSButton   *printROICoordList;
    IBOutlet NSButton   *centerViewTest;
    IBOutlet NSButton   *rotationTest;
    
    IBOutlet NSTextField *rotationTheta;
    
    IBOutlet NSButton   *viewEachROI;
    
    IBOutlet NSTextField *secondsPerROI;
}

- (id) init;
- (id) initWithOwner:(id *) theOwner;

- (IBAction) openMprViewer: (id) sender;
- (IBAction) printCameraInfo: (id) sender;
- (IBAction) printROICoordList: (id) sender;
- (IBAction) centerViewTest: (id) sender;
- (IBAction) rotationTest: (id) sender;
- (IBAction) viewEachROI: (id) sender;

- (void) centerOnEachROI: (NSTimer *) theTimer;
- (void) rotateViewInc: (NSTimer *) theTimer;

- (void) centerView: (MPRDCMView *) theView 
             onPt3D: (float *) pt3D;
- (void) rotateView: (MPRDCMView *) theView
            degrees: (float) theta;


- (Point3D *) rotateVector: (Point3D *) vectorOne
              aroundVector: (Point3D *) axis
                   byTheta: (float) theta;

- (Point3D *) normalizePt: (Point3D *) thePt;

@end
