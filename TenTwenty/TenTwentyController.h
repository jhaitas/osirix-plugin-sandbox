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
    
    NSDate              *startTime;
    
    NSString            *studyName;
    NSString            *seriesName;
    
    MPRController       *mprViewer;
    MPRDCMView          *sliceView;
    
    int                 stepNumber;
    
    ROI                 *skullTrace;
    NSArray             *searchPaths;
    
    NSMutableDictionary     *landmarks;
    NSMutableDictionary     *allPoints;
    NSMutableDictionary     *extraPoints;
    
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

- (void) resliceViewFromInstructions:   (NSDictionary *) sliceInstructions;
- (void) skullTraceFromInstructions:    (NSDictionary *) traceInstructions;
- (void) divideTraceFromInstructions:   (NSDictionary *) divideInstructions;

- (VRController *) openVrViewer;

#pragma mark Work Methods

- (void) getROI: (ROI *)        roi
        fromPix: (DCMPix *)     pix 
  toDicomCoords: (float [3])    location;

- (void) pointNamed: (NSString *)   name
      toDicomCoords: (float [3])    dicomCoords;

- (void) roiWithName: (NSString *)  name 
       toDicomCoords: (float [3])   dicomCoords;

- (ROI *) findRoiWithName: (NSString *) thisName;

- (DCMPix *) findPixWithROI: (ROI *) roi;

- (void) placeElectrodes: (NSArray *) electrodesToPlace;

- (void) addPoint: (float [3]) dicomCoords;
- (void) addPoint: (float [3]) dicomCoords
         withName: (NSString *) name;

- (void) add3DPointsNamed: (NSArray *)      pointsToAdd
               to3DViewer: (VRController *) theViewer;

- (void) addPointToAllPoints: (Point3D *)   point
                    withName: (NSString *)  name;

- (NSString *) pathForTenTwentyData;
- (NSString *) pathForStudyData;
- (NSString *) pathForSeriesData;
- (NSString *) pathForAnalysisData;

- (void) sliceToFileNamed: (NSString *)  fileName;

@end
