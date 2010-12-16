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
#import "TraceController.h"
#import "LineDividerController.h"

#define FBOX(x) [NSNumber numberWithFloat:x]

@interface TenTwentyController : NSWindowController {
    id owner;
    
    ViewerController    *viewerController;
    ViewerController    *viewerML;
    
    float               minScalpValue,maxSkullValue;
    
    ResliceController       *reslicer;
    TraceController         *tracer;
    LineDividerController   *lineDivider;
    
    NSMutableDictionary     *landmarks;
    NSMutableDictionary     *allPoints;
    
    // HUD Outlets
    IBOutlet NSPanel        *tenTwentyHUDPanel;
    IBOutlet NSTextField    *minScalpTextField;
    IBOutlet NSTextField    *maxSkullTextField;
    IBOutlet NSButton       *performTenTwentyMeasurments;
}

- (id) init;
- (id) initWithOwner:(id *) theOwner;

#pragma mark Interface Methods
- (IBAction) performTenTwentyMeasurments: (id) sender;

- (void) identifyLandmarks;

- (void) runInstructions: (NSDictionary *) theInstructions;
- (void) divideTrace: (ROI *) theTrace
              inView: (MPRDCMView *) theView
   usingInstructions: (NSDictionary *) divideInstructions;

- (void) placeElectrodes: (NSArray *) electrodesToPlace;

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


@end
