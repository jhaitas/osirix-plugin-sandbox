//
//  TenTwentyController.m
//  TenTwenty
//
//  Created by John Haitas on 10/8/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "TenTwentyController.h"

@implementation TenTwentyController

- (id) init
{
    if (self = [super init]) {        
        [NSBundle loadNibNamed:@"TenTwentyHUD.nib" owner:self];
        [minScalp setFloatValue:45.0];
        [maxSkull setFloatValue:45.0];
        
        // set ROIs to display name only
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ROITEXTNAMEONLY"];
    }
    return self;
}

- (void) prepareTenTwenty: (PluginFilter *) thePlugin
{
    owner = thePlugin;
    
    viewerController    = [owner valueForKey:@"viewerController"];
    
    
    landmarks   = [[NSMutableDictionary alloc] init];
    allPoints   = [[NSMutableDictionary alloc] init];
    
    [self identifyLandmarks];
    [allPoints addEntriesFromDictionary:landmarks];
}

#pragma mark Interface Methods
- (IBAction) performTenTwentyMeasurments: (id) sender
{
    NSDictionary    *tenTwentyInstructions;
    NSArray         *instructionList;
    
    [self openMprViewer];
    
    
    tenTwentyInstructions   = [self loadInstructions];
    instructionList         = [tenTwentyInstructions objectForKey:@"instructionSteps"]; 
    
    for (NSDictionary *theseInstructions in instructionList) {
        [self runInstructions:theseInstructions];
        
    }
    
    // delete all existing ROIs
    [viewerController roiDeleteAll:self];
    
    // place electrodes according to dictionary
    [self placeElectrodes:[tenTwentyInstructions objectForKey:@"electrodesToPlace"]];
    
    [mprViewer close];
    [tenTwentyHUDPanel close];
}

- (void) identifyLandmarks
{
    NSArray *landmarkNames;
    Point3D *dicomPoint;
    
    landmarkNames = [NSArray arrayWithObjects:@"brow",@"apex",@"inion",@"A1",@"A2",nil];
    
    for (NSString *name in landmarkNames) {
        float dicomCoords[3];
        [self roiWithName:name toDicomCoords:dicomCoords];
        dicomPoint = [Point3D pointWithX:dicomCoords[0] y:dicomCoords[1] z:dicomCoords[2]];
        NSLog(@"%@ %@",name,dicomPoint);
        [landmarks setObject:dicomPoint forKey:name]; 
    }
}

- (void) openMprViewer
{
    mprViewer = [viewerController openMPRViewer];
    [viewerController place3DViewerWindow:(NSWindowController *)mprViewer];
    [mprViewer showWindow:self];
    [[mprViewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[mprViewer window] title], [[viewerController window] title]]];
}

- (NSDictionary *) loadInstructions
{
    NSString        *bundlePath,*instructionsFilename;
    
    bundlePath              = [[NSBundle bundleWithIdentifier:@"edu.vanderbilt.tentwenty"] resourcePath];
    instructionsFilename    = [NSString stringWithFormat:@"%@/tenTwentyInstructions.plist",bundlePath];
    
    return [[[NSDictionary alloc] initWithContentsOfFile:instructionsFilename] autorelease];
}

- (void) runInstructions: (NSDictionary *) theInstructions
{
    NSDictionary    *sliceInstructions,*divideInstructions;
    ROI             *skullTrace;
    MPRDCMView      *theView;
    DCMPix          *thePix;
    
    sliceInstructions = [theInstructions objectForKey:@"sliceInstructions"];
    divideInstructions = [theInstructions objectForKey:@"divideInstructions"];
    
    theView = mprViewer.mprView3;
    
    thePix = [self      resliceView: theView
                   fromInstructions: sliceInstructions  ];
    
    skullTrace = [self skullTraceInPix: thePix
                      fromInstructions: sliceInstructions ];
    
    [self       divideTrace: skullTrace
                      inPix: thePix
           fromInstructions: divideInstructions     ];
    
    
    [theView detect2DPointInThisSlice];
    [theView.curRoiList addObject:skullTrace];
    [theView display];
}

- (DCMPix *) resliceView: (MPRDCMView *) theView
        fromInstructions: (NSDictionary *) sliceInstructions
{
    ResliceController *reslicer;
    
    reslicer = [[ResliceController alloc] initWithFactor:[[mprViewer valueForKey:@"hiddenVRView"] factor]];
    
    [reslicer planeInView:theView
               withVertex:[allPoints objectForKey:[sliceInstructions objectForKey:@"vertex"]]
               withPoint1:[allPoints objectForKey:[sliceInstructions objectForKey:@"point1"]]
               withPoint2:[allPoints objectForKey:[sliceInstructions objectForKey:@"point2"]] ];
    
    [reslicer release];
    
    return theView.pix;
}


- (ROI *) skullTraceInPix: (DCMPix *) thePix
         fromInstructions: (NSDictionary *) traceInstructions
{
    Point3D *pointA,*pointB,*vertex;
    ROI     *skullTrace;
    
    TraceController *tracer;
    
    tracer  = [[TraceController alloc] initWithMinScalp:[minScalp floatValue] andMaxSkull:[maxSkull floatValue]];
    
    pointA = [allPoints objectForKey:[traceInstructions objectForKey:@"point1"]];
    pointB = [allPoints objectForKey:[traceInstructions objectForKey:@"point2"]];
    vertex = [allPoints objectForKey:[traceInstructions objectForKey:@"vertex"]];
    
    skullTrace =  [tracer skullTraceInPix: thePix
                                  fromPtA: pointA
                                 toPointB: pointB
                               withVertex: vertex ];
    
    // set it selected so we can see how well our intermediate points fit
    [skullTrace setROIMode:ROI_selected];
    
    [tracer release];
    
    return skullTrace;
}

- (void) divideTrace: (ROI *) theTrace
               inPix: (DCMPix *) thePix
    fromInstructions: (NSDictionary *) divideInstructions;
{
    LineDividerController *lineDivider;
    NSArray *newROIs;
    
    lineDivider = [[LineDividerController alloc] initWithPix:thePix];
    [lineDivider setDistanceDict:divideInstructions];
    [lineDivider divideLine:theTrace];
    
    newROIs = [lineDivider intermediateROIs];
    
    for (ROI *r in newROIs) {
        float dicomCoords[3];
        
        //get the dicom coords
        [thePix convertPixX:r.rect.origin.x pixY:r.rect.origin.y toDICOMCoords:dicomCoords];
        
        [allPoints setObject:[Point3D pointWithX:dicomCoords[0] y:dicomCoords[1] z:dicomCoords[2]] forKey:r.name]; 
                
        [self addPoint:dicomCoords withName:r.name];
    }
    [lineDivider release];
}




#pragma mark Work Methods

- (void) getROI: (ROI *) thisROI fromPix: (DCMPix *) thisPix toDicomCoords:(float *) location
{                
    NSMutableArray *roiPoints = [ thisROI points ];
    NSPoint roiCenterPoint;
    
    // calc center of the ROI
    if ( [ thisROI type ] == t2DPoint ) {
        // ROI has a bug which causes miss-calculating center of 2DPoint roi
        roiCenterPoint = [ [ roiPoints objectAtIndex: 0 ] point ];
    } else {
        roiCenterPoint = [ thisROI centroid ];
    }
    
    // convert pixel values to mm values
    [thisPix convertPixX:roiCenterPoint.x
                    pixY:roiCenterPoint.y
           toDICOMCoords:location            ];
    DLog(@"%@ coordinates = (%.3f,%.3f,%.3f)\n",thisROI.name,location[0],location[1],location[2]);
}


- (void) pointNamed: (NSString *) name
      toDicomCoords: (float *) dicomCoords
{
    Point3D *point;
    
    point = [allPoints objectForKey:name];
    
    if (point == nil) {
        NSLog(@"Point named %@ not found",name);
        return;
    }
    
    dicomCoords[0] = point.x;
    dicomCoords[1] = point.y;
    dicomCoords[2] = point.z;
}

- (void) roiWithName: (NSString *) name
       toDicomCoords: (float *) dicomCoords
{
    [self roiWithName:name inViewerController: viewerController toDicomCoords:dicomCoords];
}

- (void) roiWithName: (NSString *) name
  inViewerController: (ViewerController *) vc
       toDicomCoords: (float *) dicomCoords
{
    DCMPix              *pix;
    ROI                 *roi;
    
    roi = [self findRoiWithName:name inViewerController:vc];
    pix = [self findPixWithROI:roi inViewerController:vc];
    
    if (pix == nil || roi == nil) {
        NSLog(@"Failed to find ROI named %@ in viewerController",name);
    }
    
    [pix convertPixX:roi.rect.origin.x pixY:roi.rect.origin.y toDICOMCoords:dicomCoords];
    NSLog(@"%@ found with dicomCoords %f,%f,%f",name,dicomCoords[0],dicomCoords[1],dicomCoords[2]);
}

- (ROI *) findRoiWithName: (NSString *) thisName
       inViewerController: (ViewerController *)vc
{
    ROI     *thisROI;
    
    thisROI = nil;
    
    for (NSArray *roiList in [[vc imageView] dcmRoiList]) {
        for (ROI *r in roiList) {
            if ([r.name isEqualToString:thisName]) {
                thisROI = r;
            }
        }
    }
    
    return thisROI;
}

- (ROI *) findRoiWithName: (NSString *) thisName
{
    return [self findRoiWithName:thisName inViewerController:viewerController];
}

- (DCMPix *) findPixWithROI: (ROI *) thisROI
         inViewerController: (ViewerController *) vc
{
    int     thisIndex;
    NSArray *thisRoiList;
    
    thisIndex = -1;
    
    for (thisRoiList in [[vc imageView] dcmRoiList]) {
        if ([thisRoiList containsObject:thisROI]) {
            thisIndex = [[[vc imageView] dcmRoiList] indexOfObjectIdenticalTo:thisRoiList];
        }
    }
    
    if (thisIndex == -1) {
        return nil;
    }
    
    return [[[vc imageView] dcmPixList] objectAtIndex:thisIndex];
}

- (DCMPix *) findPixWithROI: (ROI *) thisROI
{
    return [self findPixWithROI:thisROI inViewerController:viewerController];
}


- (void) placeElectrodes: (NSArray *) electrodesToPlace
{
    float   dicomCoords[3];
    Point3D *point;
    
    for (NSString *name in electrodesToPlace) {
        point = [allPoints objectForKey:name];
        
        dicomCoords[0] = point.x;
        dicomCoords[1] = point.y;
        dicomCoords[2] = point.z;
        
        [self addPoint:dicomCoords withName:name];
    }
}

- (void) addPoint:(float [3])dicomCoords
{
    [self addPoint:dicomCoords withName:[ROI defaultName]];
}

- (void) addPoint: (float [3]) dicomCoords
         withName: (NSString *) name
{
    float   sliceCoords[3];
    ROI     *roi;
    DCMPix  *pix;
    
    pix = [[viewerController pixList] objectAtIndex: 0];
    
    
    [pix convertDICOMCoords: dicomCoords 
              toSliceCoords: sliceCoords 
                pixelCenter: YES            ];
    
    sliceCoords[0] /= pix.pixelSpacingX;
    sliceCoords[1] /= pix.pixelSpacingY;
    sliceCoords[2] /= pix.sliceInterval;
    
    sliceCoords[2] = round(sliceCoords[2]);
    
    if (sliceCoords[ 2] >= 0 && sliceCoords[ 2] < [[viewerController pixList] count])
    {
        roi = [[[ROI alloc] initWithType: t2DPoint 
                                        : pix.pixelSpacingX 
                                        : pix.pixelSpacingY 
                                        : [DCMPix originCorrectedAccordingToOrientation: pix] ] autorelease];
        
        roi.name = name;
        
        [roi setROIRect: NSMakeRect( sliceCoords[ 0], sliceCoords[ 1], 0, 0)];
        
        [[[viewerController roiList] objectAtIndex: sliceCoords[ 2]] addObject: roi];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object: roi userInfo: nil];
    }
}

@end
