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
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ROITEXTIFSELECTED"];
    }
    return self;
}

- (void) prepareTenTwenty: (PluginFilter *) thePlugin
{
    owner = thePlugin;
    
    viewerController    = [owner valueForKey:@"viewerController"];
    
    
    brainROIs   = [[viewerController roisWithName:@"Brain"] retain];
    
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
    
    [self removeBrain];
    
    [self openMprViewer];
    
    
    tenTwentyInstructions   = [self loadInstructions];
    instructionList         = [tenTwentyInstructions objectForKey:@"instructionSteps"]; 
    
    for (NSDictionary *theseInstructions in instructionList) {
        int stepNum = 1 + [instructionList indexOfObject:theseInstructions];
        [self runInstructions:theseInstructions];
        [self sliceToFileNamed:[NSString stringWithFormat:@"step-%d.png",stepNum]];
        
    }
    
    // close MPR viewer and Ten Twenty HUD
    [mprViewer close];
    [tenTwentyHUDPanel close];
    
    // make only brain visible
    [self displayOnlyBrain];
    
    // delete all existing ROIs
    [viewerController roiDeleteAll:self];
    
    // place electrodes according to dictionary
    [self placeElectrodes:[tenTwentyInstructions objectForKey:@"electrodesToPlace"]];
    
    // update the view
    [viewerController updateImage:self];
    
    // display 3D Viewer
    [self openVrViewer];
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

- (void) removeBrain
{
    ROI     *roi;
    short   allRois;
    BOOL    propagateIn4D,outside,revert;
    float   minValue,maxValue,newValue;
    
    
    
    roi             = [brainROIs objectAtIndex:0];
    allRois         = 0;
    propagateIn4D   = NO;
    outside         = NO;
    minValue        = -FLT_MAX;
    maxValue        = FLT_MAX;
    newValue        = 0.0;
    revert          = NO;
    
    // deselect any selected ROIs
    for (ROI *r in [viewerController selectedROIs]) {
        [r setROIMode: ROI_sleep];
    }
    
    // select all brain ROIs
    for (ROI *r in brainROIs) {
        [r setROIMode: ROI_selected];
    }
    
    // set pixels inside brain ROIs to 0
    [viewerController roiSetPixels: roi
                                  : allRois
                                  : propagateIn4D
                                  : outside
                                  : minValue
                                  : maxValue
                                  : newValue
                                  : revert          ];
}

- (void) displayOnlyBrain
{
    ROI     *roi;
    short   allRois;
    BOOL    propagateIn4D,outside,revert;
    float   minValue,maxValue,newValue;
    
    // deselect any selected ROIs
    for (ROI *r in [viewerController selectedROIs]) {
        [r setROIMode: ROI_sleep];
    }
    
    // select all brain ROIs
    for (ROI *r in brainROIs) {
        [r setROIMode: ROI_selected];
    }
    
    // revert the series
    [viewerController revertSeries: self];
    
    roi             = [brainROIs objectAtIndex:0];
    allRois         = 0;
    propagateIn4D   = NO;
    outside         = YES;
    minValue        = -FLT_MAX;
    maxValue        = FLT_MAX;
    newValue        = 0.0;
    revert          = NO;
    
    // set pixels outside brain ROIs to 0
    [viewerController roiSetPixels: roi
                                  : allRois
                                  : propagateIn4D
                                  : outside
                                  : minValue
                                  : maxValue
                                  : newValue
                                  : revert          ];
}
                    
- (void) openMprViewer
{
    mprViewer = [viewerController openMPRViewer];
    [viewerController place3DViewerWindow:(NSWindowController *)mprViewer];
    [mprViewer showWindow:self];
    [[mprViewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[mprViewer window] title], [[viewerController window] title]]];
    
    sliceView = mprViewer.mprView3;
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
    NSDictionary *sliceInstructions,*divideInstructions;
    
    sliceInstructions = [theInstructions objectForKey:@"sliceInstructions"];
    divideInstructions = [theInstructions objectForKey:@"divideInstructions"];
    
    [self resliceViewFromInstructions: sliceInstructions];
    
    [self skullTraceFromInstructions: sliceInstructions];
    
    [self divideTraceFromInstructions: divideInstructions];
    
    // detect our new electrodes
    [sliceView detect2DPointInThisSlice];
    
    // add the search paths and search paths to view
    [sliceView.curRoiList addObjectsFromArray:searchPaths];
    
    // add the skull trace
    [sliceView.curRoiList addObject:skullTrace];
    
    // select the skull trace
    [skullTrace setROIMode:ROI_selected];
    
    [sliceView display];
    
}

- (void) resliceViewFromInstructions: (NSDictionary *) sliceInstructions
{
    ResliceController *reslicer;
    
    reslicer = [[ResliceController alloc] initWithView:sliceView];
    
    [reslicer planeWithVertex:[allPoints objectForKey:[sliceInstructions objectForKey:@"vertex"]]
                   withPoint1:[allPoints objectForKey:[sliceInstructions objectForKey:@"point1"]]
                   withPoint2:[allPoints objectForKey:[sliceInstructions objectForKey:@"point2"]] ];
    
    [reslicer release];
}


- (void) skullTraceFromInstructions: (NSDictionary *) traceInstructions
{
    TraceController *tracer;
    Point3D         *pointA,*pointB,*vertex;
    
    tracer  = [[TraceController alloc] initWithPix: sliceView.pix
                                          minScalp: [minScalp floatValue]
                                          maxSkull: [maxSkull floatValue] ];
    
    pointA = [allPoints objectForKey:[traceInstructions objectForKey:@"point1"]];
    pointB = [allPoints objectForKey:[traceInstructions objectForKey:@"point2"]];
    vertex = [allPoints objectForKey:[traceInstructions objectForKey:@"vertex"]];
    
    [tracer traceFromPtA: pointA
                toPointB: pointB
              withVertex: vertex ];
    
    skullTrace  = tracer.trace;
    searchPaths = tracer.searchPaths;
    
    [tracer release];
}

- (void) divideTraceFromInstructions: (NSDictionary *) divideInstructions;
{
    LineDividerController *lineDivider;
    
    lineDivider = [[LineDividerController alloc] initWithPix:sliceView.pix];
    [lineDivider setDistanceDict:divideInstructions];
    [lineDivider divideLine:skullTrace];
    
    // Step through each of the intermediate ROIs
    for (ROI *r in [lineDivider intermediateROIs]) {
        float dicomCoords[3];
        
        //get the dicom coords
        [sliceView.pix convertPixX:r.rect.origin.x pixY:r.rect.origin.y toDICOMCoords:dicomCoords];
        
        [allPoints setObject:[Point3D pointWithX:dicomCoords[0] y:dicomCoords[1] z:dicomCoords[2]] forKey:r.name]; 
                
        [self addPoint:dicomCoords withName:r.name];
    }
    [lineDivider release];
}

- (VRController *) openVrViewer
{
    VRController    *viewer;
    float           iwl, iww;
    
    viewer = [viewerController openVRViewerForMode:@"VR"];

    [viewer ApplyCLUTString: [viewerController curCLUTMenu]];
    [[viewerController imageView] getWLWW:&iwl :&iww];
    [viewer setWLWW:iwl :iww];
    [viewerController place3DViewerWindow: viewer];
    [viewer load3DState];
    [viewer showWindow:viewerController];			
    [[viewer window] makeKeyAndOrderFront:viewerController];
    [[viewer window] display];
    [[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
    
    return viewer;
}



#pragma mark Work Methods

- (void) getROI: (ROI *)        roi
        fromPix: (DCMPix *)     pix
  toDicomCoords: (float [3])    location
{                
    NSMutableArray *roiPoints = [ roi points ];
    NSPoint roiCenterPoint;
    
    // calc center of the ROI
    if ( [ roi type ] == t2DPoint ) {
        // ROI has a bug which causes miss-calculating center of 2DPoint roi
        roiCenterPoint = [ [ roiPoints objectAtIndex: 0 ] point ];
    } else {
        roiCenterPoint = [ roi centroid ];
    }
    
    // convert pixel values to mm values
    [pix convertPixX:roiCenterPoint.x
                pixY:roiCenterPoint.y
       toDICOMCoords:location            ];
    DLog(@"%@ coordinates = (%.3f,%.3f,%.3f)\n",roi.name,location[0],location[1],location[2]);
}


- (void) pointNamed: (NSString *)   name
      toDicomCoords: (float [3])      dicomCoords
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
    DCMPix              *pix;
    ROI                 *roi;
    
    roi = [self findRoiWithName:name];
    pix = [self findPixWithROI:roi];
    
    if (pix == nil || roi == nil) {
        NSLog(@"Failed to find ROI named %@ in viewerController",name);
    }
    
    [pix convertPixX:roi.rect.origin.x pixY:roi.rect.origin.y toDICOMCoords:dicomCoords];
    NSLog(@"%@ found with dicomCoords %f,%f,%f",name,dicomCoords[0],dicomCoords[1],dicomCoords[2]);
}

- (ROI *) findRoiWithName: (NSString *) thisName
{
    ROI     *roi;
    
    roi = nil;
    
    for (NSArray *roiList in [[viewerController imageView] dcmRoiList]) {
        for (ROI *r in roiList) {
            if ([r.name isEqualToString:thisName]) {
                roi = r;
            }
        }
    }
    
    return roi;
}

- (DCMPix *) findPixWithROI: (ROI *) roi
{
    int     thisIndex;
    NSArray *thisRoiList;
    
    thisIndex = -1;
    
    for (thisRoiList in [[viewerController imageView] dcmRoiList]) {
        if ([thisRoiList containsObject:roi]) {
            thisIndex = [[[viewerController imageView] dcmRoiList] indexOfObjectIdenticalTo:thisRoiList];
        }
    }
    
    if (thisIndex == -1) {
        return nil;
    }
    
    return [[[viewerController imageView] dcmPixList] objectAtIndex:thisIndex];
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
    
    if (sliceCoords[ 2] >= 0 && sliceCoords[2] < [[viewerController pixList] count])
    {
        roi = [[[ROI alloc] initWithType: t2DPoint 
                                        : pix.pixelSpacingX 
                                        : pix.pixelSpacingY 
                                        : [DCMPix originCorrectedAccordingToOrientation: pix] ] autorelease];
        
        roi.name = name;
        
        [roi setROIRect: NSMakeRect( sliceCoords[0], sliceCoords[1], 0, 0)];
        
        [[[viewerController roiList] objectAtIndex: sliceCoords[2]] addObject: roi];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object: roi userInfo: nil];
    }
}


- (void) sliceToFileNamed: (NSString *)  fileName
{
    NSImage             *image;
    NSBitmapImageRep    *imageRep;
    NSData              *imageRepData;
    
    image           = [sliceView nsimage];
    imageRep        = [[image representations] objectAtIndex: 0];
    imageRepData    = [imageRep representationUsingType: NSPNGFileType
                                             properties: nil];
    [imageRepData writeToFile: fileName
                   atomically: NO];
}

@end
