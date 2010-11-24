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

#import "TenTwentyFilter.h"
#import "LineDividerController.h"
#import "StereotaxCoord.h"

#define FBOX(x) [NSNumber numberWithFloat:x]

@interface TenTwentyController : NSWindowController {
    id owner;
    
    ViewerController    *viewerController;
    ViewerController    *viewerML;
    
    BOOL                foundNasion,foundInion;
    StereotaxCoord      *nasion,*inion;
    StereotaxCoord      *Cz;
    StereotaxCoord      *userP1,*userP2;
    NSMutableDictionary *orientation,*direction;
    
    float               minScalpValue,maxSkullValue;
    
    DCMPix              *midlineSlice;
    DCMPix              *coronalCzSlice;
    
    ROI                 *midlineSkullTrace;
    ROI                 *coronalSkullTrace;
    
    NSDictionary        *midlineElectrodes;
    NSDictionary        *coronalElectrodes;
    
    NSMutableDictionary *allElectrodes;
    
    LineDividerController *ld;
    
    MPRController       *mprViewer;
    
    // HUD Outlets
    IBOutlet NSPanel        *tenTwentyHUDPanel;
    IBOutlet NSTextField    *minScalpTextField;
    IBOutlet NSTextField    *maxSkullTextField;
    IBOutlet NSButton       *identifyNasionAndInionButton;
    IBOutlet NSButton       *placeMidlineElectrodesButton;
    IBOutlet NSButton       *placeCoronalElectrodesButton;
    IBOutlet NSButton       *openMPRViewerButton;
    IBOutlet NSButton       *mouseTest;
}

@property (assign) BOOL foundNasion,foundInion;

- (id) init;
- (id) initWithOwner:(id *) theOwner;

#pragma mark Interface Methods
- (IBAction) identifyNasionAndInionButtonClick: (id) sender;
- (IBAction) placeMidlineElectrodesButtonClick: (id) sender;
- (IBAction) placeCoronalElectrodesButtonClick: (id) sender;
- (IBAction) openMPRViewerButtonClick: (id) sender;
- (IBAction) mouseTest: (id) sender;


#pragma mark Work Methods
- (void) findUserInput;
- (void) getROI: (ROI *)    thisROI 
        fromPix: (DCMPix *) thisPix 
  toDicomCoords: (float *)  location;


- (void) computeOrientation;
- (void) remapNasionAndInion;

- (void) placeMidlineElectrodes;
- (void) traceSkullMidline;

- (void) resliceCoronalAtCz;
- (void) watchViewerML: (NSTimer *) theTimer;
- (void) placeCoronalElectrodes;
- (void) traceSkullCzCoronal;

- (NSPoint) lowerElectrode: (ROI *) thisROI
                   inSlice: (DCMPix *) thisSlice;
- (NSPoint) extendPoint: (ROI *) thisROI
                inSlice: (DCMPix *) thisSlice
              withDirML: (int) directionML
              withDirDV: (int) directionDV;

- (void) storeElectrodesWithNames: (NSArray *) electrodeNames
               inViewerController: (ViewerController *) vc;
- (void) storeElectrodesWithNames: (NSArray *) electrodeNames;

- (void) removeSkullTrace: (ROI *) thisSkullTrace
       inViewerController: (ViewerController *) vc;
- (void) removeSkullTrace: (ROI *) thisSkullTrace;

- (ROI *) findRoiWithName: (NSString *) thisName
       inViewerController: (ViewerController *)vc;
- (ROI *) findRoiWithName: (NSString *) thisName;

- (DCMPix *) findPixWithROI: (ROI *) thisROI
         inViewerController: (ViewerController *) vc;
- (DCMPix *) findPixWithROI: (ROI *) thisROI;

- (BOOL) isPoint: (NSPoint) thePoint onSlice: (DCMPix *) thisPix;

- (void) printAllElectrodesInStereotax;
- (void) placeElectrodesInViewerController: (ViewerController *) vc;


#pragma mark MPR class methods
- (NSPoint) centerLines: (MPRDCMView *) sender;
- (void) computeCrossReferenceLinesBetween: (MPRDCMView*) mp1 and:(MPRDCMView*) mp2 result: (float[2][3]) s;


#pragma mark synthesize Mouse
- (void) synthClickDragFromPt: (CGPoint) pt1
                         toPt: (CGPoint) pt2;

@end
