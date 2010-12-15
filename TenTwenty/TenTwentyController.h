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
#import "ResliceController.h"
#import "LineDividerController.h"
#import "StereotaxCoord.h"

#define FBOX(x) [NSNumber numberWithFloat:x]

@interface TenTwentyController : NSWindowController {
    id owner;
    
    ViewerController    *viewerController;
    ViewerController    *viewerML;
    
    BOOL                foundBrow,foundInion;
    StereotaxCoord      *brow,*inion;
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
    
    LineDividerController   *ld;
    ResliceController       *reslicer;
    
    // HUD Outlets
    IBOutlet NSPanel        *tenTwentyHUDPanel;
    IBOutlet NSTextField    *minScalpTextField;
    IBOutlet NSTextField    *maxSkullTextField;
    IBOutlet NSButton       *newTraceMethod;
}

@property (assign) BOOL foundBrow,foundInion;

- (id) init;
- (id) initWithOwner:(id *) theOwner;

#pragma mark Interface Methods
- (IBAction) newTraceMethod: (id) sender;


- (void) runInstructions: (NSDictionary *) theInstructions;
- (ROI *) skullTraceFromInstructions: (NSDictionary *) traceInstructions;
- (void) findSkullInView: (MPRDCMView *) theView
            fromPosition: (float [3]) thePos
             inDirection: (float [3]) theDir
              toPosition: (float [3]) finalPos;
- (void) divideTrace: (ROI *) theTrace
              inView: (MPRDCMView *) theView
   usingInstructions: (NSDictionary *) divideInstructions;

#pragma mark Work Methods
- (void) getROI: (ROI *)    thisROI 
        fromPix: (DCMPix *) thisPix 
  toDicomCoords: (float *)  location;

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

@end
