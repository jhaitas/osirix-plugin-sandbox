//
//  TraceController.m
//  TenTwenty
//
//  Created by John Haitas on 12/16/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "TraceController.h"

@implementation TraceController

@synthesize minScalp,maxSkull,searchPaths,trace;

- (id) initWithPix: (DCMPix *)  thePix
          minScalp: (float)     theMinScalp
          maxSkull: (float)     theMaxSkull
{
    if (self = [super init]) {
        pix         = thePix;
        minScalp    = theMinScalp;
        maxSkull    = theMaxSkull;
        
        searchPaths = nil;
    }
    return self;
}

- (void) traceFromPtA: (Point3D *) pointAPt
             toPointB: (Point3D *) pointBPt
           withVertex: (Point3D *) vertexPt
{
    int         i,numSections,numPoints;
    float       pointA[3],pointB[3],vertex[3],midpoint[3],displacement[3],stepSize[3],searchDir[3];
    float       xVector[3],yVector[3],unitX[3],unitY[3];
    float       pixelSpacingX,pixelSpacingY;
    NSMutableArray      *intermediatePoints,*theseSearchPaths;
    
    theseSearchPaths    = [[NSMutableArray alloc] init];
    intermediatePoints  = [[NSMutableArray alloc] init];
    
    numSections = 20;
    numPoints = numSections + 1;
    
    // parameters necessary for initializting a new ROI
    pixelSpacingX   = [pix pixelSpacingX];
    pixelSpacingY   = [pix pixelSpacingY];
    
    // get the DICOM coords of each point
    [self point3d: pointAPt toDicomCoords:pointA];
    [self point3d: pointBPt toDicomCoords:pointB];
    [self point3d: vertexPt toDicomCoords:vertex];
    
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
    
    yVector[0] = vertex[0] - midpoint[0];
    yVector[1] = vertex[1] - midpoint[1];
    yVector[2] = vertex[2] - midpoint[2];
    
    // make our directional vectors unit vectors
    UNIT(unitX,xVector);
    UNIT(unitY,yVector);
    
    for (i = 0; i < numPoints; i++)
    {
        float   startPosition[3],sliceCoords[3];
        float   thetaRad;
        NSPoint startPoint,endPoint;
        ROI     *thisSearchPath;
        
        // compute theta value ... 
        // .. 0 at point A, PI at point B (180 degrees)
        thetaRad = i * (PI / (float)numSections);
        
        // place points on straight line from point A to point B
        startPosition[0] = pointA[0] + (stepSize[0] * (float) i);
        startPosition[1] = pointA[1] + (stepSize[1] * (float) i);
        startPosition[2] = pointA[2] + (stepSize[2] * (float) i);
        
        // bend points toward vertex
        startPosition[0] += (yVector[0]) * sin(thetaRad);
        startPosition[1] += (yVector[1]) * sin(thetaRad);
        startPosition[2] += (yVector[2]) * sin(thetaRad);
        
        [pix convertDICOMCoords:startPosition toSliceCoords:sliceCoords];
        startPoint = NSMakePoint(sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY);
        
        // compute search direction
        searchDir[0] = (unitX[0] * cos(thetaRad)) + (unitY[0] * sin(thetaRad));
        searchDir[1] = (unitX[1] * cos(thetaRad)) + (unitY[1] * sin(thetaRad));
        searchDir[2] = (unitX[2] * cos(thetaRad)) + (unitY[2] * sin(thetaRad));        
        
        // search for skull
        endPoint = [self findFromPosition:startPosition inDirection:searchDir];
        
        // allocate and initialize a new 'tMesure' ROI
        thisSearchPath = [[[ROI alloc] initWithType: tMesure
                                                   : pixelSpacingX
                                                   : pixelSpacingY
                                                   : NSMakePoint(0.0, 0.0)] autorelease];
        
        thisSearchPath.name = [NSString stringWithFormat:@"point %d search path",i+1];
        
        [thisSearchPath setPoints:[NSMutableArray arrayWithObjects:[MyPoint point:startPoint],[MyPoint point:endPoint],nil]];
        
        [theseSearchPaths addObject:thisSearchPath];
        
        // add this point to intermediate points array
        [intermediatePoints addObject:[MyPoint point:endPoint]];
    }
    
    searchPaths = [NSArray arrayWithArray:theseSearchPaths];
    
    // allocate and initialize a new 'Open Polygon' ROI
    trace = [[[ROI alloc] initWithType: tOPolygon
                                      : pixelSpacingX
                                      : pixelSpacingY
                                      : NSMakePoint(0.0, 0.0)] autorelease];
    
    
    trace.name = [NSString stringWithString:@"trace"];
    
    // set points for spline
    [trace setPoints:intermediatePoints];
}

- (NSPoint) findFromPosition: (float [3])    position
                 inDirection: (float [3])    direction
{
    float   sliceCoords[3],pixelSpacingX,pixelSpacingY;
    float   scalingFactor;
    float   thisMin,thisMean,thisMax;
    BOOL    foundScalp,foundSkull;
    ROI     *thisROI;
    NSPoint point;
    
    foundScalp = NO;
    foundSkull = NO;
    
    scalingFactor = 0.1;
    
    pixelSpacingX   = pix.pixelSpacingX;
    pixelSpacingY   = pix.pixelSpacingY;
    
    
    // allocate and initialize a new ROI
    thisROI = [[ROI alloc] initWithType: t2DPoint
                                       : pixelSpacingX
                                       : pixelSpacingY
                                       : NSMakePoint(0.0, 0.0)];
    
    // look for scalp
    while (!foundScalp) {
        // move point in direction
        position[0] += (direction[0] * scalingFactor);
        position[1] += (direction[1] * scalingFactor);
        position[2] += (direction[2] * scalingFactor);
        
        // convert back to slice coords
        [pix convertDICOMCoords:position toSliceCoords:sliceCoords];
        
        // set the position of the ROI
        thisROI.rect = NSMakeRect(sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY, 0.0, 0.0);
        
        // determine current pixel mean
        [pix computeROI:thisROI :&thisMean :NULL :NULL :&thisMin :&thisMax];
        
        // detect if we have found the scalp
        if (thisMax > minScalp) {
            foundScalp = YES;
        }
        
        // be sure we haven't fallen to the bottom of the slice
        if (![self isPointOnPix:thisROI.rect.origin]) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
    
    // reverse direction and locate the skull
    while (!foundSkull) {
        // move point in opposite direction
        position[0] -= (direction[0] * scalingFactor);
        position[1] -= (direction[1] * scalingFactor);
        position[2] -= (direction[2] * scalingFactor);
        
        // convert back to slice coords
        [pix convertDICOMCoords:position toSliceCoords:sliceCoords];
        
        // set the position of the ROI
        thisROI.rect = NSMakeRect(sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY, 0.0, 0.0);
        
        // determine current pixel mean
        [pix computeROI:thisROI :&thisMean :NULL :NULL :&thisMin :&thisMax];
        
        // detect if we have found the scalp
        if (thisMin < maxSkull) {
            foundSkull = YES;
        }
        
        // be sure we haven't fallen to the bottom of the slice
        if (![self isPointOnPix:thisROI.rect.origin]) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
    [thisROI release];
    
    [pix convertDICOMCoords:position toSliceCoords:sliceCoords];
    point = NSMakePoint(sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY);

    return point;
}

- (BOOL) isPointOnPix: (NSPoint) point
{
    if (point.x >= 0 && point.y >= 0 && point.x < pix.pwidth && point.y < pix.pheight) {
        return YES;
    }
    return NO;
}

- (void) point3d: (Point3D *) point
   toDicomCoords: (float [3]) dicomCoords
{
    dicomCoords[0] = point.x;
    dicomCoords[1] = point.y;
    dicomCoords[2] = point.z;
}

@end
