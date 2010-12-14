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
- (IBAction) identifyBrowAndInionButtonClick: (id) sender
{
    // there should be an ROI named 'brow' and 'inion'
    [self findUserInput];
    
    // check if 'brow' and 'inion' were found
    if (foundBrow && foundInion) {        
        [self computeOrientation];
        
        // remap coordinates per computed orientation
        [self remapBrowAndInion];
        
        // disable this button
        [identifyBrowAndInionButton setEnabled:NO];
        
        // enable next button in sequence
        [placeMidlineElectrodesButton setEnabled:YES];
    } else {
        // failed to locate 'brow' and 'inion'
        // notify the user through the NSRunAlertPanel        
        NSRunAlertPanel(NSLocalizedString(@"Plugin Error", nil),
                        NSLocalizedString(@"Unable to locate 'brow' and 'inion'!", nil), 
                        nil, nil, nil);
    }
}

- (IBAction) placeMidlineElectrodesButtonClick: (id) sender
{
    // disable 'Place Midline Electrodes' button
    [placeMidlineElectrodesButton setEnabled:NO];
    
    // get values from HUD
    minScalpValue = [minScalpTextField floatValue];
    maxSkullValue = [maxSkullTextField floatValue];
    
    // lock the text fields
    [minScalpTextField setEditable:NO];
    [maxSkullTextField setEditable:NO];
    
    // disable the text fields
    [minScalpTextField setEnabled:NO];
    [maxSkullTextField setEnabled:NO];
    
    // place the electrodes
    [self placeMidlineElectrodes];
    
    // enable 'Place Coronal Electrodes' button
    [placeCoronalElectrodesButton setEnabled:YES];
}

- (IBAction) placeCoronalElectrodesButtonClick: (id) sender
{
    // enable 'Place Coronal Electrodes' button
    [placeCoronalElectrodesButton setEnabled:NO];

    // coronal reslice at 'Cz' electrode
    [self resliceCoronalAtCz];
}

- (IBAction) newTraceMethod: (id) sender
{
    NSMutableDictionary *measureInstructions,*sliceInstructions,*divideInstructions;
    
    measureInstructions = [[NSMutableDictionary alloc] init];
    sliceInstructions   = [[NSMutableDictionary alloc] init];
    divideInstructions  = [[NSMutableDictionary alloc] init];
    
    [sliceInstructions setObject:[NSString stringWithString:@"apex"]    forKey:@"vertex"];
    [sliceInstructions setObject:[NSString stringWithString:@"brow"]    forKey:@"point1"];
    [sliceInstructions setObject:[NSString stringWithString:@"inion"]   forKey:@"point2"];
    
    divideInstructions = [[NSDictionary alloc] initWithObjectsAndKeys:  FBOX(.1),@"Fpz",
                                                                        FBOX(.3),@"Fz",
                                                                        FBOX(.5),@"Cz",
                                                                        FBOX(.7),@"Pz",
                                                                        FBOX(.9),@"Oz", nil ];
    
    [measureInstructions setObject:sliceInstructions forKey:@"sliceInstructions"];
    [measureInstructions setObject:divideInstructions forKey:@"divideInstructions"];
    
    [self runInstructions:measureInstructions];
    
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
- (void) findUserInput
{
    int     i,ii;
    float   location[3];
    ROI     *selectedROI;    
    
    NSArray *pixList;
    NSArray *roiList;
    NSArray *thisRoiList;
    DCMPix  *thisPix;
    
    pixList = [viewerController pixList];
    roiList = [viewerController roiList];
    
    // step through each ROI list
    for (i = 0; i < [roiList count]; i++) {
        thisRoiList = [roiList objectAtIndex:i];
        thisPix = [pixList objectAtIndex:i];
        // step through each ROI in the current ROI list
        for (ii = 0; ii < [thisRoiList count]; ii++) {
            selectedROI = [thisRoiList objectAtIndex:ii];
            // check if this ROI is named 'brow'
            if ([selectedROI.name isEqualToString:@"brow"]) {
                [self getROI:selectedROI fromPix:thisPix toDicomCoords:location];
                brow = [[StereotaxCoord alloc] initWithName:selectedROI.name
                                                       withDicomCoords:location ];
                foundBrow = YES;
                
                // FIXME ... need to verify this
                midlineSlice = thisPix;
            }
            // check if this ROI is named 'inion'
            if ([selectedROI.name isEqualToString:@"inion"]) {
                [self getROI:selectedROI fromPix:thisPix toDicomCoords:location];
                inion = [[StereotaxCoord alloc] initWithName:selectedROI.name
                                             withDicomCoords:location ];
                foundInion = YES;
            }
        }
    }
}

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

// coordinates natively in (x,y,z) ...
// ... greatest difference between brow and inion should be AP
// ... ML should be same in brow and inion
// ... DV should be smaller difference than AP
- (void) computeOrientation
{
    int             i,firstIndex,secondIndex;
    int             indexAP,indexML,indexDV;
    float           thisFloat,firstFloat,secondFloat;
    int             dir[3];
    NSNumber        *diffAP,*diffML,*diffDV;
    NSMutableArray  *diff;
    
    
    diffAP  = [[NSNumber alloc] initWithDouble:(brow.AP - inion.AP)];
    diffML  = [[NSNumber alloc] initWithDouble:(brow.ML - inion.ML)];
    diffDV  = [[NSNumber alloc] initWithDouble:(brow.DV - inion.DV)];
    
    // set directions based on difference between brow and inion ...
    // ... ML is assumed to be zero and will be given a direction of 1
    dir[0]  = ([diffAP floatValue] >= 0 ? 1 : -1);
    dir[1]  = ([diffML floatValue] >= 0 ? 1 : -1);
    dir[2]  = ([diffDV floatValue] >= 0 ? 1 : -1);
    
    diff    = [[NSMutableArray alloc] initWithObjects:diffAP,diffML,diffDV,nil];
    
    
    // no longer need these objects...
    // ... they have been incorporated into diff array
    [diffAP release];
    [diffML release];
    [diffDV release];
    
    
    // initialize values that aren't acceptable after the following routine
    indexML = -1;
    
    // first we identify and eliminate ML ...
    // ... there should be only one plane with no difference
    for (i = 0; i < [diff count]; i++) {
        thisFloat = [[diff objectAtIndex:i] floatValue];
        if (thisFloat == 0.0) {
            // found ML ... store its index
            indexML = i;
        }
    }
    
    // We failed to find the ML index
    if (indexML == -1) {
        [diff release];
        return;
    }
    
    // initialize values that won't be acceptable after the following routine
    firstIndex      = -1;
    secondIndex     = -1;
    firstFloat     = 0.0;
    secondFloat    = 0.0;
    
    // now find which magnitude is greater between remaining diffs
    // [diff count] should equal 3
    // we don't want the first for loop to hit the last diff element
    for (i = 0; i < ([diff count] - 1); i++) {
        // ignore item identified as ML
        if (i == indexML) continue;
        firstFloat = [[diff objectAtIndex:i] floatValue];
        firstIndex = i;
    }
    
    // start with the index after previously selected first index
    for (i = firstIndex + 1; i < [diff count]; i++) {
        // ignore item identified as ML
        if (i == indexML) continue;
        secondFloat = [[diff objectAtIndex:i] floatValue];
        secondIndex = i;
    }
    
    // release diff object because we no longer need it
    [diff release];
    
    // set appropriate indices based on magnitude comparison
    if (fabs(firstFloat) > fabs(secondFloat)) {
        indexAP = firstIndex;
        indexDV = secondIndex;
    } else {
        indexAP = secondIndex;
        indexDV = firstIndex;
    }
    
    DLog(@"dirAP ,dirML ,dirDV  = %d,%d,%d\n",dir[indexAP],dir[indexML],dir[indexDV]);
    
    // set orientation dictionary objects
    [orientation setObject:[NSNumber numberWithInt:indexAP] forKey:@"AP"];
    [orientation setObject:[NSNumber numberWithInt:indexML] forKey:@"ML"];
    [orientation setObject:[NSNumber numberWithInt:indexDV] forKey:@"DV"];
    
    // set direction dictionary objects
    [direction setObject:[NSNumber numberWithInt:dir[indexAP]] forKey:@"AP"];
    [direction setObject:[NSNumber numberWithInt:dir[indexML]] forKey:@"ML"];
    [direction setObject:[NSNumber numberWithInt:dir[indexDV]] forKey:@"DV"];
}

- (void) remapBrowAndInion
{
    [brow remapWithOrientation:orientation];
    [inion remapWithOrientation:orientation];   
}

- (void) placeMidlineElectrodes
{
    // set the current image to the midline slice image
    [[viewerController imageView] setIndex:[[[viewerController imageView] dcmPixList] indexOfObjectIdenticalTo:midlineSlice]];
    
    // trace the skull from 'brow' to 'inion'
    [self traceSkullMidline];
    
    ld = [[LineDividerController alloc] initWithViewerController:viewerController];
    [ld setDistanceDict:midlineElectrodes];
    [ld divideLine:midlineSkullTrace];
    
    // store the electrodes
    [self storeElectrodesWithNames:[midlineElectrodes allKeys]];
    
    // remove the skull trace
    [self removeSkullTrace:midlineSkullTrace inViewerController:viewerController];
}

- (void) traceSkullMidline
{
    int             i,numIntermediatePoints,stepDir;
    int             indexAP,indexML,indexDV;
    int             thisRoiType,sliceIndex;
    float           thisAP,thisML,thisDV;
    float           displacement,stepSize;
    float           dicomCoords[3],sliceCoords[3];
    float           pixelSpacingX,pixelSpacingY;
    ROI             *thisROI;
    NSPoint         thisPoint;
    NSMutableArray  *intermediatePoints;
    
    intermediatePoints      = [[NSMutableArray alloc] init];
    
    indexAP = [[orientation objectForKey:@"AP"] intValue];
    indexML = [[orientation objectForKey:@"ML"] intValue];
    indexDV = [[orientation objectForKey:@"DV"] intValue];
    
    numIntermediatePoints   = 15;
    displacement            = brow.AP - inion.AP;
    stepSize                = displacement / (numIntermediatePoints -1);
    stepDir                 = [[direction objectForKey:@"AP"] intValue];
    
    thisDV = brow.DV + (20 * [[direction objectForKey:@"DV"] intValue]);
    thisML = brow.ML;
    
    dicomCoords[indexML] = thisML;
    dicomCoords[indexDV] = thisDV;
    
    // parameters necessary for initializting a new ROI
    thisRoiType     = t2DPoint;
    pixelSpacingX   = [midlineSlice pixelSpacingX];
    pixelSpacingY   = [midlineSlice pixelSpacingY];
    
    sliceIndex = [[[viewerController imageView] dcmPixList] indexOfObject:midlineSlice];
    
    for (i = 0; i < numIntermediatePoints; i++) {
        thisAP =  brow.AP - (stepDir * (stepSize * i));
        
        dicomCoords[indexAP] = thisAP;
        
        [midlineSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
        
        
        // allocate and initialize a new ROI
        thisROI = [[ROI alloc] initWithType:thisRoiType
                                           :pixelSpacingX
                                           :pixelSpacingY
                                           :NSMakePoint(0.0, 0.0)];
        
        // move the ROI to the correct location
        thisROI.rect = NSOffsetRect(thisROI.rect, sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY);
        
        // give the ROI the correct name
        thisROI.name = [NSString stringWithString:@"intermediate"];
        
        // lower the electrode to the surface of the skull
        thisPoint = [self lowerElectrode:thisROI inSlice:midlineSlice];
        
        [intermediatePoints addObject:[MyPoint point:thisPoint]];
        
        // add the new ROI to the correct ROI list
        //        [[[[viewerController imageView] dcmRoiList] objectAtIndex:sliceIndex] addObject:thisROI];
    }
    
    
    // allocate and initialize a new 'Open Polygon' ROI
    thisROI = [[ROI alloc] initWithType:tOPolygon
                                       :pixelSpacingX
                                       :pixelSpacingY
                                       :NSMakePoint(0.0, 0.0)];
    
    thisROI.name = [NSString stringWithString:@"skull trace"];
    
    // set points for spline
    [thisROI setPoints:intermediatePoints];
    
    // add the new ROI to the correct ROI list
    [[[[viewerController imageView] dcmRoiList] objectAtIndex:sliceIndex] addObject:thisROI];
    
    // store the midline skull trace for future reference
    midlineSkullTrace = thisROI;
    
    // update screen
    [viewerController updateImage:self];
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

- (void) resliceCoronalAtCz
{
    int     indexML,bestSlice;
    float   dicomCoords[3],sliceCoords[3];
    ROI     *tmpCz,*thisROI;
    DCMPix  *thisPix;
    
    // identify Cz and store it in stereotax coords for later computations
    tmpCz = [self findRoiWithName:@"Cz"];
    
    // determine dicom coords from Cz electrode
    [self getROI:tmpCz fromPix:midlineSlice toDicomCoords:dicomCoords];
    
    // create stereotax coord for Cz
    Cz = [[StereotaxCoord alloc] initWithName:@"Cz"
                              withDicomCoords:dicomCoords ];
    
    // remap coords to orientation
    [Cz remapWithOrientation:orientation];
    
    // Now we have Cz from which we will reslice on coronal plane
    
    indexML = [[orientation objectForKey:@"ML"] intValue];
    
    thisROI = [self findRoiWithName:@"Cz"];
    thisPix = [self findPixWithROI:thisROI];
    
    // get the DICOM coords of this ROI
    [self getROI:thisROI fromPix:thisPix toDicomCoords:dicomCoords];
    
    // create a new viewer window that will display the new slice
    viewerML = [owner duplicateCurrent2DViewerWindow];
    
    // reslice DICOM on ML plane
    [viewerML processReslice: indexML :NO];
    
    // get best slice to see Cz    
    bestSlice = [DCMPix nearestSliceInPixelList:[[viewerML imageView] dcmPixList]
                                withDICOMCoords:dicomCoords
                                    sliceCoords:sliceCoords                         ];
    
    
    // View slice with Cz
    [[viewerML imageView] setIndex: bestSlice];
    
    // store this slice for later computations
    coronalCzSlice = [[viewerML imageView] curDCM];
    
    // update screen
    [viewerML updateImage:self];
    
    // make the new viewer key window and bring it to the front
    [[viewerML window] makeKeyAndOrderFront:self];
    
    // give the user 2D point tool
    [[viewerML imageView] setCurrentTool:t2DPoint];
    
    // start a timer to wait for user to place 2 ROIs
    [NSTimer scheduledTimerWithTimeInterval:2
                                     target:self
                                   selector:@selector(watchViewerML:)
                                   userInfo:nil
                                    repeats:YES];   
    
    DLog(@"%@ at location %f,%f,%f\n",thisROI.name,dicomCoords[0],dicomCoords[1],dicomCoords[2]);
}

- (void) watchViewerML: (NSTimer *) theTimer
{
    float   location[3];
    ROI     *selectedROI;
        
    if ([[[viewerML imageView] curRoiList] count] >= 2) {
        // we have located 2 ROIs
        [theTimer invalidate];
        
        // get the first ROI and store it in StereotaxCoord object
        selectedROI = [[[viewerML imageView] curRoiList] objectAtIndex:1];
        [self getROI:selectedROI fromPix:coronalCzSlice toDicomCoords:location];
        userP1 = [[StereotaxCoord alloc] initWithName:selectedROI.name
                                      withDicomCoords:location          ];
        
        // get the second ROI and store it in StereotaxCoord object
        selectedROI = [[[viewerML imageView] curRoiList] objectAtIndex:0];
        [self getROI:selectedROI fromPix:coronalCzSlice toDicomCoords:location];
        userP2 = [[StereotaxCoord alloc] initWithName:selectedROI.name
                                      withDicomCoords:location          ];
        
        // remap coordinates according to previously calculated orientation        
        [userP1 remapWithOrientation:orientation];
        [userP2 remapWithOrientation:orientation];
        
        [self placeCoronalElectrodes];
    }
}

- (void) placeCoronalElectrodes
{
    // produce the skull trace that will later be 
    [self traceSkullCzCoronal];
    
    ld = [[LineDividerController alloc] initWithViewerController:viewerML];
    [ld setDistanceDict:coronalElectrodes];
    [ld divideLine:coronalSkullTrace];
    
    // remove the skull trace
    [self removeSkullTrace:coronalSkullTrace inViewerController:viewerML];
    
    // update screen
    [[viewerML imageView] setNeedsDisplay:YES];
    
    // store the stereotax coords of new electrodes
    [self storeElectrodesWithNames:[coronalElectrodes allKeys]
                inViewerController:viewerML                     ];
    
    // close the ML slice window
    [[viewerML window] performClose:self];
    
    // delete all existing ROI before we place new ROIs
    [viewerController roiDeleteAll:self];
    
    // place electrodes in viewer
    [self placeElectrodesInViewerController:viewerController];
}

- (void) traceSkullCzCoronal
{
    int             i,numIntermediatePoints;
    int             expandDirML,expandDirDV;
    int             indexAP,indexML,indexDV;
    int             thisRoiType,sliceIndex;
    float           thisAP,thisML,thisDV;
    float           displacementML,displacementDV;
    float           stepSizeML,stepSizeDV;
    float           dicomCoords[3],sliceCoords[3];
    float           pixelSpacingX,pixelSpacingY;
    ROI             *thisROI;
    NSPoint         thisPoint;
    NSMutableArray  *oPolyPoints;
    NSMutableArray  *intermediatePoints;
    
    DLog(@"%@\n",Cz);
    DLog(@"%@\n",userP1);
    DLog(@"%@\n",userP2);
    
    intermediatePoints      = [[NSMutableArray alloc] init];
    
    indexAP = [[orientation objectForKey:@"AP"] intValue];
    indexML = [[orientation objectForKey:@"ML"] intValue];
    indexDV = [[orientation objectForKey:@"DV"] intValue];
    
    numIntermediatePoints   = 10;
    
    // determine displacement and step-size for ML
    displacementML          = userP1.ML - Cz.ML;
    stepSizeML              = displacementML / (numIntermediatePoints - 1);
    
    // determine displacement and step-size for DV
    displacementDV          = userP1.DV - Cz.DV;
    stepSizeDV              = displacementDV / (numIntermediatePoints - 1);
    
    // AP is going to be constant for this operation
    thisAP = userP1.AP;
    dicomCoords[indexAP] = thisAP;
    
    // parameters necessary for initializting a new ROI
    thisRoiType     = t2DPoint;
    pixelSpacingX   = [coronalCzSlice pixelSpacingX];
    pixelSpacingY   = [coronalCzSlice pixelSpacingY];
    
    sliceIndex = [[[viewerML imageView] dcmPixList] indexOfObject:coronalCzSlice];
        
    // first go from userP1 to Cz
    for (i = 1; i < (numIntermediatePoints - 1); i++) {
        thisML = userP1.ML - (stepSizeML * i);
        thisDV = userP1.DV - (stepSizeDV * i);
        
        dicomCoords[indexML] = thisML;
        dicomCoords[indexDV] = thisDV;
        
        [coronalCzSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
        
        // allocate and initialize a new ROI
        thisROI = [[ROI alloc] initWithType:thisRoiType
                                           :pixelSpacingX
                                           :pixelSpacingY
                                           :NSMakePoint(0.0, 0.0)];
        
        // move the ROI to the correct location
        thisROI.rect = NSOffsetRect(thisROI.rect, sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY);
        
        // give the ROI the correct name
        thisROI.name = [NSString stringWithFormat:@"i%d",i];
 
        // logic to identify direction of expansion
        expandDirML = stepSizeML > 0 ? 1 : -1;
        expandDirDV = stepSizeDV > 0 ? -1 : 1;
        
        // lower the electrode to the surface of the skull
        thisPoint = [self extendPoint:thisROI 
                              inSlice:coronalCzSlice
                            withDirML:expandDirML
                            withDirDV:expandDirDV       ];
 
        [intermediatePoints addObject:[MyPoint point:thisPoint]];
    }
    
    oPolyPoints = [NSMutableArray arrayWithArray:intermediatePoints];
    [intermediatePoints removeAllObjects];
    
    // determine displacement and step-size for ML
    displacementML          = Cz.ML - userP2.ML;
    stepSizeML              = displacementML / (numIntermediatePoints - 1);
    
    // determine displacement and step-size for DV
    displacementDV          = Cz.DV - userP2.DV;
    stepSizeDV              = displacementDV / (numIntermediatePoints - 1);
    
    // continue from Cz to userP2
    for (i = 1; i < (numIntermediatePoints - 1); i++) {
        thisML = Cz.ML - (stepSizeML * i);
        thisDV = Cz.DV - (stepSizeDV * i);
        
        dicomCoords[indexML] = thisML;
        dicomCoords[indexDV] = thisDV;
        
        [coronalCzSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
        
        // allocate and initialize a new ROI
        thisROI = [[ROI alloc] initWithType:thisRoiType
                                           :pixelSpacingX
                                           :pixelSpacingY
                                           :NSMakePoint(0.0, 0.0)];
        
        // move the ROI to the correct location
        thisROI.rect = NSOffsetRect(thisROI.rect, sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY);
        
        // give the ROI the correct name
        thisROI.name = [NSString stringWithFormat:@"i%d",i];
                
        // logic to identify direction of expansion
        expandDirML = stepSizeML > 0 ? -1 : 1;
        expandDirDV = stepSizeDV > 0 ? 1 : -1;
        
         // lower the electrode to the surface of the skull
        thisPoint = [self extendPoint:thisROI 
                              inSlice:coronalCzSlice
                            withDirML:expandDirML
                            withDirDV:expandDirDV       ];
 
        [intermediatePoints addObject:[MyPoint point:thisPoint]];
    }
    
    // add second set of intermediat points to oPolyPoints array
    [oPolyPoints addObjectsFromArray:intermediatePoints];
    
    // put userP1 at beginning of array
    dicomCoords[indexAP] = userP1.AP;
    dicomCoords[indexML] = userP1.ML;
    dicomCoords[indexDV] = userP1.DV;
    
    [coronalCzSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];

    [oPolyPoints insertObject:[MyPoint point:NSMakePoint(sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY)]
                      atIndex:0                                                                                         ];

    // put userP2 at end of array
    dicomCoords[indexAP] = userP2.AP;
    dicomCoords[indexML] = userP2.ML;
    dicomCoords[indexDV] = userP2.DV;
    
    // convert DICOM coords to slice coords
    [coronalCzSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
    
    // add this point to the oPolyPoints array
    [oPolyPoints addObject:[MyPoint point:NSMakePoint(sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY)]];
    
    // allocate and initialize a new 'Open Polygon' ROI
    thisROI = [[ROI alloc] initWithType:tOPolygon
                                       :pixelSpacingX
                                       :pixelSpacingY
                                       :NSMakePoint(0.0, 0.0)];
    
    thisROI.name = [NSString stringWithString:@"coronal skull trace"];
    
    // set points for spline
    [thisROI setPoints:oPolyPoints];
    
    // add the new ROI to the correct ROI list
    [[[[viewerML imageView] dcmRoiList] objectAtIndex:sliceIndex] addObject:thisROI];
    
    // reference this skull trace so it may be added or removed later
    coronalSkullTrace = thisROI;
    
    // update screen
    [viewerController updateImage:self];
}

- (NSPoint) lowerElectrode: (ROI *) thisROI inSlice: (DCMPix *) thisSlice
{
    int     indexDV,directionDV;
    float   thisMin,thisMean,thisMax;
    double  pixelSpacingX,pixelSpacingY;
    float   dicomCoords[3],sliceCoords[3];
    BOOL    foundScalp,foundSkull;
    NSPoint roiPosition;
    NSPoint offsetShift;
    
    // initialize values
    indexDV         = [[orientation objectForKey:@"DV"] intValue];
    directionDV     = [[direction objectForKey:@"DV"] intValue];
    foundScalp      = NO;
    foundSkull      = NO;
    thisMin         = -1.0;
    thisMean        = -1.0;
    thisMax         = -1.0;
    pixelSpacingX   = [thisSlice pixelSpacingX];
    pixelSpacingY   = [thisSlice pixelSpacingY];
    
    // select this ROI (prerequisite for [ROI roiMove: :] method)
    [thisROI setROIMode: ROI_selected];
    
    if (indexDV == 2) {
        DLog(@"DV index indicates DV goes across slices... no implementation for this yet\n");
        return NSMakePoint(0, 0);
    }
    
    // drop till we locate the skull
    while (!foundSkull) {
        roiPosition = thisROI.rect.origin;
        
        // get DICOM coordinates (in mm)
        [thisSlice convertPixX:roiPosition.x pixY:roiPosition.y toDICOMCoords:dicomCoords];
        
        // drop point .01 mm on DV plane
        dicomCoords[indexDV] -= (directionDV * .01);
        
        // convert back to slice coords
        [thisSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
        
        // determine how coordinates should be shifted
        offsetShift.x = (sliceCoords[0] / pixelSpacingX) - roiPosition.x;
        offsetShift.y = (sliceCoords[1] / pixelSpacingY) - roiPosition.y;
        
        // shift the ROI
        [thisROI roiMove:offsetShift :TRUE];
        
        // determine current pixel mean
        [thisSlice computeROI:thisROI :&thisMean :NULL :NULL :&thisMin :&thisMax];
        
        // detect if we have found the skull
        if (thisMin < maxSkullValue) {
            foundSkull = YES;
        }
        
        // be sure we haven't fallen to the bottom of the slice
        if (![self isPoint:thisROI.rect.origin onSlice:thisSlice]) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
    
    // put this ROI back to sleep
    [thisROI setROIMode: ROI_sleep];
    
    return NSMakePoint(thisROI.rect.origin.x, thisROI.rect.origin.y);
}

- (NSPoint) extendPoint: (ROI *) thisROI
                inSlice: (DCMPix *) thisSlice
              withDirML: (int) directionML
              withDirDV: (int) directionDV
{
    int     indexML,indexDV;
    float   thisMin,thisMean,thisMax;
    double  pixelSpacingX,pixelSpacingY;
    float   dicomCoords[3],sliceCoords[3];
    BOOL    foundScalp,foundSkull;
    NSPoint roiPosition;
    NSPoint offsetShift;
    
    DLog(@"directionML = %d\n",directionML);
    DLog(@"directionDV = %d\n",directionDV);
    
    // initialize values
    indexML         = [[orientation objectForKey:@"ML"] intValue];
    indexDV         = [[orientation objectForKey:@"DV"] intValue];
    foundScalp      = NO;
    foundSkull      = NO;
    thisMin         = -1.0;
    thisMean        = -1.0;
    thisMax         = -1.0;
    pixelSpacingX   = [thisSlice pixelSpacingX];
    pixelSpacingY   = [thisSlice pixelSpacingY];
    
    // select this ROI (prerequisite for [ROI roiMove: :] method)
    [thisROI setROIMode: ROI_selected];
    
    if (indexDV == 2) {
        DLog(@"DV index indicates DV goes across slices... no implementation for this yet\n");
        return NSMakePoint(0, 0);
    }
    
    // extend till we locate the skull
    while (!foundSkull) {
        roiPosition = thisROI.rect.origin;
        
        // get DICOM coordinates (in mm)
        [thisSlice convertPixX:roiPosition.x pixY:roiPosition.y toDICOMCoords:dicomCoords];
        
        // drop point .01 mm on ML and DV plane
        dicomCoords[indexML] += (directionML * .01);
        dicomCoords[indexDV] += (directionDV * .01);
        
        // convert back to slice coords
        [thisSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
        
        // determine how coordinates should be shifted
        offsetShift.x = (sliceCoords[0] / pixelSpacingX) - roiPosition.x;
        offsetShift.y = (sliceCoords[1] / pixelSpacingY) - roiPosition.y;
        
        // shift the ROI
        [thisROI roiMove:offsetShift :TRUE];
        
        // determine current pixel mean
        [thisSlice computeROI:thisROI :&thisMean :NULL :NULL :&thisMin :&thisMax];
        
        // detect if we have found the skull
        if (thisMin < maxSkullValue) {
            foundSkull = YES;
        }
        
        // be sure we haven't fallen to the bottom of the slice
        if (![self isPoint:thisROI.rect.origin onSlice:thisSlice]) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
    
    // extend till we locate the scalp
    while (!foundScalp) {
        roiPosition = thisROI.rect.origin;
        
        // get DICOM coordinates (in mm)
        [thisSlice convertPixX:roiPosition.x pixY:roiPosition.y toDICOMCoords:dicomCoords];
        
        // drop point .1 mm on ML and DV plane
        dicomCoords[indexML] += (directionML * .01);
        dicomCoords[indexDV] += (directionDV * .01);
        
        // convert back to slice coords
        [thisSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
        
        // determine how coordinates should be shifted
        offsetShift.x = (sliceCoords[0] / pixelSpacingX) - roiPosition.x;
        offsetShift.y = (sliceCoords[1] / pixelSpacingY) - roiPosition.y;
        
        // shift the ROI
        [thisROI roiMove:offsetShift :TRUE];
        
        // determine current pixel mean
        [thisSlice computeROI:thisROI :&thisMean :NULL :NULL :&thisMin :&thisMax];
        
        // detect if we have found the scalp
        if (thisMax > minScalpValue) {
            foundScalp = YES;
        }
        
        // be sure we haven't fallen to the bottom of the slice
        if (![self isPoint:thisROI.rect.origin onSlice:thisSlice]) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
    
    // now backup until we are back on skull
    foundSkull = NO;
    
    // extend till we locate the skull
    while (!foundSkull) {
        roiPosition = thisROI.rect.origin;
        
        // get DICOM coordinates (in mm)
        [thisSlice convertPixX:roiPosition.x pixY:roiPosition.y toDICOMCoords:dicomCoords];
        
        // drop point .01 mm on ML and DV plane
        dicomCoords[indexML] -= (directionML * .01);
        dicomCoords[indexDV] -= (directionDV * .01);
        
        // convert back to slice coords
        [thisSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
        
        // determine how coordinates should be shifted
        offsetShift.x = (sliceCoords[0] / pixelSpacingX) - roiPosition.x;
        offsetShift.y = (sliceCoords[1] / pixelSpacingY) - roiPosition.y;
        
        // shift the ROI
        [thisROI roiMove:offsetShift :TRUE];
        
        // determine current pixel mean
        [thisSlice computeROI:thisROI :&thisMean :NULL :NULL :&thisMin :&thisMax];
        
        // detect if we have found the skull
        if (thisMin < maxSkullValue) {
            foundSkull = YES;
        }
        
        // be sure we haven't fallen to the bottom of the slice
        if (![self isPoint:thisROI.rect.origin onSlice:thisSlice]) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
 
    // put this ROI back to sleep
    [thisROI setROIMode: ROI_sleep];
    
    return NSMakePoint(thisROI.rect.origin.x, thisROI.rect.origin.y); 
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
