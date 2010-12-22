//
//  TenTwentyController.h
//  TenTwenty
//
//  Created by John Haitas on 10/8/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"

// @class directive is insufficient for our needs ...
// ... MPRHeaders.h contains imports needed for MPR
#import "MPRHeaders.h"

#import "Notifications.h"

#import "TenTwentyFilter.h"
#import "ResliceController.h"
#import "TraceController.h"
#import "LineDividerController.h"

#define FBOX(x) [NSNumber numberWithFloat:x]

@interface TenTwentyController : NSWindowController {
    PluginFilter    *owner;
    
    ViewerController    *viewerController;
    MPRController       *mprViewer;
    
    MPRDCMView          *sliceView;
    
    NSMutableDictionary     *landmarks;
    NSMutableDictionary     *allPoints;
    
    NSArray *brainROIs;
    
    // HUD Outlets
    IBOutlet NSPanel        *tenTwentyHUDPanel;
    IBOutlet NSTextField    *minScalp;
    IBOutlet NSTextField    *maxSkull;
    IBOutlet NSButton       *performTenTwentyMeasurments;
}

- (id) init;
- (void) prepareTenTwenty: (PluginFilter *) thePlugin;

#pragma mark Interface Methods
- (IBAction) performTenTwentyMeasurments: (id) sender;

- (void) identifyLandmarks;

- (void) removeBrain;
- (void) displayOnlyBrain;

- (void) openMprViewer;

- (NSDictionary *) loadInstructions;

- (void) runInstructions: (NSDictionary *) theInstructions;

- (void) resliceViewFromInstructions: (NSDictionary *)  sliceInstructions;
- (NSArray *) skullTraceFromInstructions: (NSDictionary *) traceInstructions;
- (void) divideTrace: (ROI *)           theTrace
    fromInstructions: (NSDictionary *)  divideInstructions;

- (VRController *) openVrViewer;

#pragma mark Work Methods

- (void) getROI: (ROI *)    thisROI 
        fromPix: (DCMPix *) thisPix 
  toDicomCoords: (float *)  location;

- (void) pointNamed: (NSString *) name
      toDicomCoords: (float *) dicomCoords;

- (void) roiWithName: (NSString *) name 
       toDicomCoords: (float *) dicomCoords;
- (void) roiWithName: (NSString *) name 
  inViewerController: (ViewerController *) vc 
       toDicomCoords: (float *) dicomCoords;

- (ROI *) findRoiWithName: (NSString *) thisName
       inViewerController: (ViewerController *)vc;
- (ROI *) findRoiWithName: (NSString *) thisName;

- (DCMPix *) findPixWithROI: (ROI *) thisROI
         inViewerController: (ViewerController *) vc;
- (DCMPix *) findPixWithROI: (ROI *) thisROI;

- (void) placeElectrodes: (NSArray *) electrodesToPlace;

- (void) addPoint: (float [3]) dicomCoords;
- (void) addPoint: (float [3]) dicomCoords
         withName: (NSString *) name;

- (void) sliceToFileNamed: (NSString *)  fileName;

@end
