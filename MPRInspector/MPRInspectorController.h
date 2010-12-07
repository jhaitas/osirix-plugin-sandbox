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
    
    ROI                 *currentROI;
    
    IBOutlet NSPanel    *mprInspectorHUD;
    IBOutlet NSButton   *openMprViewer;
    IBOutlet NSButton   *printCameraInfo;
    IBOutlet NSButton   *printROICoordList;
    IBOutlet NSButton   *centerViewTest;
    IBOutlet NSButton   *viewEachROI;
    IBOutlet NSButton   *convertRoiCoords;
}

- (id) init;
- (id) initWithOwner:(id *) theOwner;

- (IBAction) openMprViewer: (id) sender;
- (IBAction) printCameraInfo: (id) sender;
- (IBAction) printROICoordList: (id) sender;
- (IBAction) centerViewTest: (id) sender;
- (IBAction) viewEachROI: (id) sender;
- (IBAction) convertRoiCoords: (id) sender;

- (void) centerOnEachROI: (NSTimer *) theTimer;

- (void) centerView: (MPRDCMView *) theView 
             onPt3D: (float *) pt3D;

@end
