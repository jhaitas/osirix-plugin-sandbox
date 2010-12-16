//
//  TraceController.m
//  TenTwenty
//
//  Created by John Haitas on 12/16/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "TraceController.h"


@implementation TraceController

- (id) initWithOwner: (id *) theOwner
            minScalp: (float) minScalp
            maxSkull: (float) maxSkull
{
    [self init];
    owner = theOwner; 
    view = [[[owner valueForKey:@"reslicer"] valueForKey:@"mprViewer"] valueForKey:@"mprView3"];
    minScalpValue = minScalp;
    maxSkullValue = maxSkull;
    return self;
}

- (ROI *) skullTraceFromInstructions: (NSDictionary *) traceInstructions
{
    int         i,numSections,numPoints;
    int         thisRoiType;
    float       pointA[3],pointB[3],midpoint[3],displacement[3],stepSize[3],searchDir[3];
    float       xVector[3],yVector[3],unitX[3],unitY[3];
    float       point1DcmCoords[3],vertexDcmCoords[3],point2DcmCoords[3];
    float       pixelSpacingX,pixelSpacingY;
    MPRDCMView  *theView;
    DCMPix      *thePix;
    
    NSMutableArray          *intermediatePoints;
    intermediatePoints      = [[NSMutableArray alloc] init];
    
    numSections = 10;
    numPoints = numSections + 1;
    
    theView = view;
    thePix  = theView.pix;
    
    // parameters necessary for initializting a new ROI
    thisRoiType     = t2DPoint;
    pixelSpacingX   = [thePix pixelSpacingX];
    pixelSpacingY   = [thePix pixelSpacingY];
    
    // get the DICOM coords of each point
    [owner pointNamed:[traceInstructions objectForKey:@"point1"] toDicomCoords:point1DcmCoords];
    [owner pointNamed:[traceInstructions objectForKey:@"vertex"] toDicomCoords:vertexDcmCoords];
    [owner pointNamed:[traceInstructions objectForKey:@"point2"] toDicomCoords:point2DcmCoords];
    
    
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
        
        thetaRad = i * (PI / (float)numSections);
        
        // get starting positons
        startPos[0] = pointA[0] + (stepSize[0] * (float) i);
        startPos[1] = pointA[1] + (stepSize[1] * (float) i);
        startPos[2] = pointA[2] + (stepSize[2] * (float) i);
        
        startPos[0] += (yVector[0]) * sin(thetaRad);
        startPos[1] += (yVector[1]) * sin(thetaRad);
        startPos[2] += (yVector[2]) * sin(thetaRad);
        
        // compute search direction
        searchDir[0] = (unitX[0] * cos(thetaRad)) + (unitY[0] * sin(thetaRad));
        searchDir[1] = (unitX[1] * cos(thetaRad)) + (unitY[1] * sin(thetaRad));
        searchDir[2] = (unitX[2] * cos(thetaRad)) + (unitY[2] * sin(thetaRad));        
        
        // search for skull
        [self findSkullInPix:thePix fromPosition:startPos inDirection:searchDir toPosition:finalPos];
        
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
    
    [theView.curRoiList addObject:thisROI];
    
    [theView display];
    
    return thisROI;
}

- (void) findSkullInPix: (DCMPix *) thePix
           fromPosition: (float [3]) thePos
            inDirection: (float [3]) theDir
             toPosition: (float [3]) finalPos
{
    float   sliceCoords[3],pixelSpacingX,pixelSpacingY;
    float   scalingFactor;
    float   thisMin,thisMean,thisMax;
    BOOL    foundScalp,foundSkull;
    ROI     *thisROI;
    
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

- (BOOL) isPoint: (NSPoint) thePoint onSlice: (DCMPix *) thisPix
{
    if (thePoint.x >= 0 && thePoint.y >= 0 && thePoint.x < thisPix.pwidth && thePoint.y < thisPix.pheight) {
        return YES;
    }
    return NO;
}

@end
