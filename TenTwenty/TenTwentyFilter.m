//
//  TenTwentyFilter.m
//  TenTwenty
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "TenTwentyFilter.h"

@implementation TenTwentyFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{   
    foundNasion = NO;
    foundInion  = NO;
    
    // these values should be made user configurable in the future
    minScalpValue = 45.0;
    maxSkullValue = 45.0;
    
    // allocate and init orientation and direction dictionaries
    orientation = [[NSMutableDictionary alloc] init];
    direction   = [[NSMutableDictionary alloc] init];
    
    // there should be an ROI named 'nasion' and 'inion'
    [self findUserInput];
    
    // check if 'nasion' and 'inion' were found
    if (foundNasion && foundInion) {
        [self computeOrientation];
        
        // remap coordinates per computed orientation
        [nasion remapWithOrientation:orientation];
        [inion remapWithOrientation:orientation];
        
        
        [self traceSkull];
    } else {
        // notify the user through the NSRunAlertPanel        
        NSRunAlertPanel(NSLocalizedString(@"Plugin Error", nil),
                        NSLocalizedString(@"Unable to locate 'nasion' and 'inion'!", nil), 
                        nil, nil, nil);
        return -1;
    }
    
    return 0;
}



- (void) findUserInput
{
    int     i,ii;
    double  location[3];
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
            // check if this ROI is named 'nasion'
            if ([selectedROI.name isEqualToString:@"nasion"]) {
                [self getROI:selectedROI fromPix:thisPix toCoords:location];
                nasion = [[StereotaxCoord alloc] initWithName:selectedROI.name
                                                       withAP:location[0] 
                                                       withML:location[1] 
                                                       withDV:location[2]            ];
                foundNasion = YES;
                
                // FIXME ... need to verify this
                midlineSlice = thisPix;
            }
            // check if this ROI is named 'inion'
            if ([selectedROI.name isEqualToString:@"inion"]) {
                [self getROI:selectedROI fromPix:thisPix toCoords:location];
                inion = [[StereotaxCoord alloc] initWithName:selectedROI.name
                                                      withAP:location[0] 
                                                      withML:location[1] 
                                                      withDV:location[2]            ];
                foundInion = YES;
            }
        }
    }
}




- (void) getROI: (ROI *) thisROI fromPix: (DCMPix *) thisPix toCoords:(double *) location
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
    [thisPix convertPixDoubleX:roiCenterPoint.x
                          pixY:roiCenterPoint.y
                 toDICOMCoords:location            ];
    DLog(@"%@ coordinates (AP,ML,DV) = (%.3f,%.3f,%.3f)\n",thisROI.name,location[0],location[1],location[2]);
}


// coordinates natively in (x,y,z) ...
// ... greatest difference between nasion and inion should be AP
// ... ML should be same in nasion and inion
// ... DV should be smaller difference than AP
- (void) computeOrientation
{
    int             i,firstIndex,secondIndex;
    int             indexAP,indexML,indexDV;
    double          thisDouble,firstDouble,secondDouble;
    int             dir[3];
    NSNumber        *diffAP,*diffML,*diffDV;
    NSMutableArray  *diff;
    
    
    diffAP  = [[NSNumber alloc] initWithDouble:(nasion.AP - inion.AP)];
    diffML  = [[NSNumber alloc] initWithDouble:(nasion.ML - inion.ML)];
    diffDV  = [[NSNumber alloc] initWithDouble:(nasion.DV - inion.DV)];
    
    // set directions based on difference between nasion and inion ...
    // ... ML is assumed to be zero and will be given a direction of 1
    dir[0]  = ([diffAP doubleValue] >= 0 ? 1 : -1);
    dir[1]  = ([diffML doubleValue] >= 0 ? 1 : -1);
    dir[2]  = ([diffDV doubleValue] >= 0 ? 1 : -1);
    
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
        thisDouble = [[diff objectAtIndex:i] doubleValue];
        if (thisDouble == 0.0) {
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
    firstDouble     = 0.0;
    secondDouble    = 0.0;
    
    // now find which magnitude is greater between remaining diffs
    // [diff count] should equal 3
    // we don't want the first for loop to hit the last diff element
    for (i = 0; i < ([diff count] - 1); i++) {
        // ignore item identified as ML
        if (i == indexML) continue;
        firstDouble = [[diff objectAtIndex:i] doubleValue];
        firstIndex = i;
    }
    
    // start with the index after previously selected first index
    for (i = firstIndex + 1; i < [diff count]; i++) {
        // ignore item identified as ML
        if (i == indexML) continue;
        secondDouble = [[diff objectAtIndex:i] doubleValue];
        secondIndex = i;
    }
    
    // release diff object because we no longer need it
    [diff release];
    
    // set appropriate indices based on magnitude comparison
    if (fabs(firstDouble) > fabs(secondDouble)) {
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

- (void) traceSkull
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
    
    numIntermediatePoints   = 10;
    displacement            = nasion.AP - inion.AP;
    stepSize                = displacement / (numIntermediatePoints -1);
    stepDir                 = [[direction objectForKey:@"AP"] intValue];
    
    thisDV = nasion.DV + (20 * [[direction objectForKey:@"DV"] intValue]);
    thisML = nasion.ML;
    
    dicomCoords[indexML] = thisML;
    dicomCoords[indexDV] = thisDV;
    
    // parameters necessary for initializting a new ROI
    thisRoiType     = t2DPoint;
    pixelSpacingX   = [midlineSlice pixelSpacingX];
    pixelSpacingY   = [midlineSlice pixelSpacingY];

    sliceIndex = [[[viewerController imageView] dcmPixList] indexOfObject:midlineSlice];
    
    for (i = 0; i < numIntermediatePoints; i++) {
        thisAP =  nasion.AP - (stepDir * (stepSize * i));
        
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
    
    // drop till we locate the scalp
    while (!foundScalp) {
        roiPosition = thisROI.rect.origin;
        
        // get DICOM coordinates (in mm)
        [thisSlice convertPixX:roiPosition.x pixY:roiPosition.y toDICOMCoords:dicomCoords];
        
        // drop point .1 mm on DV plane
        dicomCoords[indexDV] -= (directionDV * .1);
        
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
        if (!(thisROI.rect.origin.x >= 0) || !(thisROI.rect.origin.y >= 0)) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
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
        if (!(thisROI.rect.origin.x >= 0) || !(thisROI.rect.origin.y >= 0)) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
    
    // put this ROI back to sleep
    [thisROI setROIMode: ROI_sleep];
    
    return NSMakePoint(thisROI.rect.origin.x, thisROI.rect.origin.y);
}

@end
