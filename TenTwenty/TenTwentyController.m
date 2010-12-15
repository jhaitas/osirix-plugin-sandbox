//
//  TenTwentyController.m
//  TenTwenty
//
//  Created by John Haitas on 10/8/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "TenTwentyController.h"

#define PI 3.14159265358979

@implementation TenTwentyController

@synthesize foundBrow,foundInion;

- (id) init
{
    if (self = [super init]) {
        foundBrow = NO;
        foundInion  = NO;
        
        
        // these values should be made user configurable in the future
        minScalpValue = 45.0;
        maxSkullValue = 45.0;
        
        [NSBundle loadNibNamed:@"TenTwentyHUD.nib" owner:self];
        [minScalpTextField setFloatValue:minScalpValue];
        [maxSkullTextField setFloatValue:maxSkullValue];
        
        
        // allocate and init orientation and direction dictionaries
        orientation = [[NSMutableDictionary alloc] init];
        direction   = [[NSMutableDictionary alloc] init];
        
        midlineElectrodes = [[NSDictionary alloc] initWithObjectsAndKeys:FBOX(.1),@"Fpz",
                                                                         FBOX(.3),@"Fz",
                                                                         FBOX(.5),@"Cz",
                                                                         FBOX(.7),@"Pz",
                                                                         FBOX(.9),@"Oz", nil ];
        
        coronalElectrodes = [[NSDictionary alloc] initWithObjectsAndKeys:FBOX(.1),@"T3",
                                                                         FBOX(.3),@"C3",
                                                                         FBOX(.7),@"C4",
                                                                         FBOX(.9),@"T4", nil ];
        
        allElectrodes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id) initWithOwner:(id *) theOwner
{
    [self init];
    owner = theOwner;
    viewerController    = [owner getViewerController];
    reslicer            = [[ResliceController alloc] initWithOwner:(id *) self];
    return self;
}

#pragma mark Interface Methods


- (IBAction) newTraceMethod: (id) sender
{
    NSString        *bundlePath,*instructionsFilename;
    NSDictionary    *tenTwentyInstructions;
    NSArray         *instructionList;
    
    bundlePath              = [[[NSBundle bundleWithIdentifier:@"edu.vanderbilt.tentwenty"] resourcePath] retain];
    instructionsFilename    = [[NSString stringWithFormat:@"%@/tenTwentyInstructions.plist",bundlePath] retain];
    tenTwentyInstructions   = [[NSDictionary alloc] initWithContentsOfFile:instructionsFilename];
    instructionList         = [tenTwentyInstructions objectForKey:@"instructionSteps"];
    
    NSLog(@"%@",bundlePath);
    NSLog(@"%@",instructionsFilename);
    
    for (NSDictionary *theseInstructions in instructionList) {
        [self runInstructions:theseInstructions];
    }    
}

- (void) runInstructions: (NSDictionary *) theInstructions
{
    NSDictionary    *sliceInstructions,*divideInstructions;
    ROI             *skullTrace;
    MPRDCMView      *theView;
    
    sliceInstructions = [theInstructions objectForKey:@"sliceInstructions"];
    divideInstructions = [theInstructions objectForKey:@"divideInstructions"];
    
    [reslicer openMprViewer];
    
    theView = reslicer.mprViewer.mprView3;
    
    [reslicer planeInView:theView
               WithVertex:[sliceInstructions objectForKey:@"vertex"]
               withPoint1:[sliceInstructions objectForKey:@"point1"]
               withPoint2:[sliceInstructions objectForKey:@"point2"] ];
    
    [theView display];
    
    skullTrace = [self skullTraceFromInstructions:sliceInstructions];
    
    [self divideTrace: skullTrace inView: theView usingInstructions: divideInstructions];
    
//    [reslicer closeMprViewer];
}

- (ROI *) skullTraceFromInstructions: (NSDictionary *) traceInstructions
{
    int         i,numSections,numPoints;
    int         thisRoiType;
    float       pointA[3],pointB[3],midpoint[3],displacement[3],stepSize[3],searchDir[3];
    float       xVector[3],yVector[3],unitX[3],unitY[3];
    float       point1DcmCoords[3],vertexDcmCoords[3],point2DcmCoords[3];
    float       pixelSpacingX,pixelSpacingY;
    ROI         *point1,*vertex,*point2;
    MPRDCMView  *theView;
    DCMPix      *thePix;
    
    NSMutableArray          *intermediatePoints;
    intermediatePoints      = [[NSMutableArray alloc] init];
    
    numSections = 10;
    numPoints = numSections + 1;
    
    theView = reslicer.mprViewer.mprView3;
    thePix  = theView.pix;
    
    // parameters necessary for initializting a new ROI
    thisRoiType     = t2DPoint;
    pixelSpacingX   = [thePix pixelSpacingX];
    pixelSpacingY   = [thePix pixelSpacingY];
    
    // get each ROI
    point1 = [reslicer get2dRoiNamed:[traceInstructions objectForKey:@"point1"] fromView:theView];
    vertex = [reslicer get2dRoiNamed:[traceInstructions objectForKey:@"vertex"] fromView:theView];
    point2 = [reslicer get2dRoiNamed:[traceInstructions objectForKey:@"point2"] fromView:theView];
    
    
    // get the DICOM coords of each ROI
    [self getROI:point1 fromPix:thePix toDicomCoords:point1DcmCoords];
    [self getROI:vertex fromPix:thePix toDicomCoords:vertexDcmCoords];
    [self getROI:point2 fromPix:thePix toDicomCoords:point2DcmCoords];
    
    // we are tracing from point A to point B ...
    // point A will be point 1
    // point B will be point 2
    pointA[0] = point1DcmCoords[0];
    pointA[1] = point1DcmCoords[1];
    pointA[2] = point1DcmCoords[2];
    
    pointB[0] = point2DcmCoords[0];
    pointB[1] = point2DcmCoords[1];
    pointB[2] = point2DcmCoords[2];
    
    // the mid point will be used to determine X and Y vectors
    midpoint[0] = (pointA[0] + pointB[0]) / 2.0;
    midpoint[1] = (pointA[1] + pointB[1]) / 2.0;
    midpoint[2] = (pointA[2] + pointB[2]) / 2.0;
    
    // displacement will be used to compute step size
    displacement[0] = pointB[0] - pointA[0];
    displacement[1] = pointB[1] - pointA[1];
    displacement[2] = pointB[2] - pointA[2];
    
    // stepSize will be use to space intermediate points evenly
    stepSize[0] = displacement[0] / (float) numSections;
    stepSize[1] = displacement[1] / (float) numSections;
    stepSize[2] = displacement[2] / (float) numSections;
    
    // compute vectors for X and Y in the image
    xVector[0] = pointA[0] - midpoint[0];
    xVector[1] = pointA[1] - midpoint[1];
    xVector[2] = pointA[2] - midpoint[2];
    
    yVector[0] = vertexDcmCoords[0] - midpoint[0];
    yVector[1] = vertexDcmCoords[1] - midpoint[1];
    yVector[2] = vertexDcmCoords[2] - midpoint[2];
    
    // make our directional vectors unit vectors
    UNIT(unitX,xVector);
    UNIT(unitY,yVector);
    
    for (i = 0; i < numPoints; i++)
    {
        float   startPos[3],finalPos[3],sliceCoords[3];
        float   thetaRad;
        NSPoint thisPoint;
        
        // get starting positons
        startPos[0] = pointA[0] + (stepSize[0] * (float) i);
        startPos[1] = pointA[1] + (stepSize[1] * (float) i);
        startPos[2] = pointA[2] + (stepSize[2] * (float) i);
        
        thetaRad = i * (PI / (float)numSections);
        
        // compute search direction
        searchDir[0] = (unitX[0] * cos(thetaRad)) + (unitY[0] * sin(thetaRad));
        searchDir[1] = (unitX[1] * cos(thetaRad)) + (unitY[1] * sin(thetaRad));
        searchDir[2] = (unitX[2] * cos(thetaRad)) + (unitY[2] * sin(thetaRad));

        // search for skull
        [self findSkullInView:theView fromPosition:startPos inDirection:searchDir toPosition:finalPos];
        
        
        // get the slice coordinates
        [thePix convertDICOMCoords:finalPos toSliceCoords:sliceCoords];
        
        thisPoint = NSMakePoint(sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY);
        
        // add this point to intermediate points array
        [intermediatePoints addObject:[MyPoint point:thisPoint]];
    }
    
    ROI *thisROI;
    
    // allocate and initialize a new 'Open Polygon' ROI
    thisROI = [[ROI alloc] initWithType:tOPolygon
                                       :pixelSpacingX
                                       :pixelSpacingY
                                       :NSMakePoint(0.0, 0.0)];
    
    
    thisROI.name = [NSString stringWithString:@"skull trace"];
    
    // set points for spline
    [thisROI setPoints:intermediatePoints];
    
    return thisROI;
}

- (void) divideTrace: (ROI *) theTrace
               inView: (MPRDCMView *) theView
   usingInstructions: (NSDictionary *) divideInstructions
{
    NSArray *newROIs;
    DCMPix *thePix;
    
    thePix = theView.pix;
    
    ld = [[LineDividerController alloc] initWithPix:thePix];
    [ld setDistanceDict:divideInstructions];
    [ld divideLine:theTrace];
    
    newROIs = [ld intermediateROIs];
    
    for (ROI *r in newROIs) {
        float dicomCoords[3];
        
        //get the dicom coords
        [thePix convertPixX:r.rect.origin.x pixY:r.rect.origin.y toDICOMCoords:dicomCoords];
        
        // create the new ROI;
        [theView add2DPoint: dicomCoords];
    }
}

- (void) findSkullInView: (MPRDCMView *) theView
            fromPosition: (float [3]) thePos
             inDirection: (float [3]) theDir
              toPosition: (float [3]) finalPos
{
    float   sliceCoords[3],pixelSpacingX,pixelSpacingY;
    float   scalingFactor;
    float   thisMin,thisMean,thisMax;
    BOOL    foundScalp,foundSkull;
    ROI     *thisROI;
    DCMPix  *thePix;
    
    thePix = theView.pix;
    
    foundScalp = NO;
    foundSkull = NO;
    
    scalingFactor = 0.1;
    
    finalPos[0] = thePos[0];
    finalPos[1] = thePos[1];
    finalPos[2] = thePos[2];
    
    pixelSpacingX   = thePix.pixelSpacingX;
    pixelSpacingY   = thePix.pixelSpacingY;
    
    
    // allocate and initialize a new ROI
    thisROI = [[ROI alloc] initWithType:t2DPoint
                                       :pixelSpacingX
                                       :pixelSpacingY
                                       :NSMakePoint(0.0, 0.0)];
    
    
    NSLog(@"theDir x,y,z = %f,%f,%f",theDir[0],theDir[1],theDir[2]);
    
    // look for scalp
    while (!foundScalp) {
        // move point in direction
        finalPos[0] += (theDir[0] * scalingFactor);
        finalPos[1] += (theDir[1] * scalingFactor);
        finalPos[2] += (theDir[2] * scalingFactor);
       
        // convert back to slice coords
        [thePix convertDICOMCoords:finalPos toSliceCoords:sliceCoords];
        
        // set the position of the ROI
        thisROI.rect = NSMakeRect(sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY, 0.0, 0.0);
        
        // determine current pixel mean
        [thePix computeROI:thisROI :&thisMean :NULL :NULL :&thisMin :&thisMax];
        
        // detect if we have found the scalp
        if (thisMax > minScalpValue) {
            foundScalp = YES;
        }
        
        // be sure we haven't fallen to the bottom of the slice
        if (![self isPoint:thisROI.rect.origin onSlice:thePix]) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
    
    // reverse direction and locate the skull
    while (!foundSkull) {
        // move point in opposite direction
        finalPos[0] -= (theDir[0] * scalingFactor);
        finalPos[1] -= (theDir[1] * scalingFactor);
        finalPos[2] -= (theDir[2] * scalingFactor);
        
        // convert back to slice coords
        [thePix convertDICOMCoords:finalPos toSliceCoords:sliceCoords];
        
        // set the position of the ROI
        thisROI.rect = NSMakeRect(sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY, 0.0, 0.0);
        
        // determine current pixel mean
        [thePix computeROI:thisROI :&thisMean :NULL :NULL :&thisMin :&thisMax];
        
        // detect if we have found the scalp
        if (thisMin < maxSkullValue) {
            foundSkull = YES;
        }
        
        // be sure we haven't fallen to the bottom of the slice
        if (![self isPoint:thisROI.rect.origin onSlice:thePix]) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
    
    [thisROI release];
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
    DLog(@"%@ coordinates (AP,ML,DV) = (%.3f,%.3f,%.3f)\n",thisROI.name,location[0],location[1],location[2]);
}

- (void) removeSkullTrace: (ROI *) thisSkullTrace inViewerController: (ViewerController *) vc
{
    NSMutableArray *thisRoiList;
    for (thisRoiList in [[vc imageView] dcmRoiList]) {
        if ([thisRoiList containsObject:thisSkullTrace]) {
            [thisRoiList removeObjectIdenticalTo:thisSkullTrace];
        }
    }
}

- (void) removeSkullTrace: (ROI *) thisSkullTrace
{
    [self removeSkullTrace:thisSkullTrace inViewerController:viewerController];
}

- (void) storeElectrodesWithNames: (NSArray *) electrodeNames
               inViewerController: (ViewerController *) vc
{
    float           dicomCoords[3];
    NSString        *thisName;
    ROI             *thisElectrode;
    DCMPix          *thisPix;
    StereotaxCoord  *thisStereotax;
    
    for (thisName in electrodeNames) {
        thisElectrode   = [self findRoiWithName:thisName inViewerController:vc];
        thisPix         = [self findPixWithROI:thisElectrode inViewerController:vc];
        
        // determine the DICOM coordinates for this electrode
        [self getROI:thisElectrode fromPix:thisPix toDicomCoords:dicomCoords];
        
        // convert to stereotax coords
        thisStereotax = [[StereotaxCoord alloc] initWithName:thisName
                                             withDicomCoords:dicomCoords ];
        
        // remap with correct orientation
        [thisStereotax remapWithOrientation:orientation];
        
        // store this stereotax coord
        [allElectrodes setObject:thisStereotax forKey:thisName];
        [thisStereotax release];
    }
    
    // print list of all electrodes with stereotax coords
    [self printAllElectrodesInStereotax];
}

- (void) storeElectrodesWithNames: (NSArray *) electrodeNames
{
    [self storeElectrodesWithNames:electrodeNames inViewerController:viewerController];
}

- (ROI *) findRoiWithName: (NSString *) thisName
       inViewerController: (ViewerController *)vc
{
    NSArray *thisRoiList;
    ROI     *thisROI;
    
    for (thisRoiList in [[vc imageView] dcmRoiList]) {
        for (thisROI in thisRoiList) {
            if ([thisROI.name isEqualToString:thisName]) {
                return thisROI;
            }
        }
    }
    
    // if we don't find the ROI return nil
    return nil;
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

- (BOOL) isPoint: (NSPoint) thePoint onSlice: (DCMPix *) thisPix
{
    if (thePoint.x >= 0 && thePoint.y >= 0 && thePoint.x < thisPix.pwidth && thePoint.y < thisPix.pheight) {
        return YES;
    }
    return NO;
}

- (void) printAllElectrodesInStereotax
{
    NSEnumerator    *enumerator;
    NSString        *key;
    
    enumerator = [allElectrodes keyEnumerator];
    DLog(@"Electrode list\n");
    DLog(@"==============\n");
    for (key in enumerator) {
        DLog(@"%@\n",[allElectrodes objectForKey:key]);
    }
    DLog(@"\n\n\n");
}

- (void) placeElectrodesInViewerController: (ViewerController *) vc
{
    int             thisRoiType,bestSlice;
    float           pixelSpacingX,pixelSpacingY;
    float           dicomCoords[3],sliceCoords[3];
    NSEnumerator    *enumerator;
    NSString        *key;
    
    enumerator = [allElectrodes keyEnumerator];
    
    // temporary pointers for creating new ROI
    ROI     *thisROI;
    
    // pointer to current DCMPix in OsiriX
    DCMPix  *thisDCMPix    = [[vc imageView] curDCM];
    
    // parameters necessary for initializting a new ROI
    thisRoiType     = t2DPoint;
    pixelSpacingX   = [thisDCMPix pixelSpacingX];
    pixelSpacingY   = [thisDCMPix pixelSpacingY];
    
    for (key in enumerator) {
        StereotaxCoord *thisElectrode = [allElectrodes objectForKey:key];
        
        DLog(@"%@\n",thisElectrode);
        
        // get DICOM coords which we will convert to slice coords
        [thisElectrode returnDICOMCoords:dicomCoords withOrientation:orientation];
        
        // find nearest slice
        bestSlice = [DCMPix nearestSliceInPixelList:[[vc imageView] dcmPixList]
                                    withDICOMCoords:dicomCoords
                                        sliceCoords:sliceCoords                                    ];
        
        // allocate and initialize a new ROI
        thisROI = [[ROI alloc] initWithType:thisRoiType
                                           :pixelSpacingX
                                           :pixelSpacingY
                                           :NSMakePoint(0.0, 0.0)];
        
        // move the ROI to the correct location
        thisROI.rect = NSOffsetRect(thisROI.rect, sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY);
        
        // give the ROI the correct name
        thisROI.name = [NSString stringWithString:thisElectrode.name];
        
        // add the new ROI to the correct ROI list
        [[[[vc imageView] dcmRoiList] objectAtIndex:bestSlice] addObject:thisROI];
        
        [thisROI release];
    }
    // update screen
    [vc updateImage:self];
}

@end
