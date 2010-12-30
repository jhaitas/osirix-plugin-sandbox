//
//  LineDividerController.m
//  TenTwenty
//
//  Created by John Haitas on 10/7/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "LineDividerController.h"


@implementation LineDividerController

- (id) init
{
    if (self = [super init]) {
        // OsiriX default scale is 2.0 ...
        // ... we want to program this so that we may change this if we want
        scaleValue			= 2.0;
        lineIntervalsDict	= [[NSDictionary alloc] initWithObjectsAndKeys:FBOX(.1),@"",
                                                                           FBOX(.3),@"",
                                                                           FBOX(.5),@"",
                                                                           FBOX(.7),@"",
                                                                           FBOX(.9),@"", nil];        
        
        currentSpline		= [[NSMutableArray alloc] initWithCapacity:0];
        currentInterPoints	= [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (id) initWithPix: (DCMPix *) pix
{
    [self init];
    thePix = pix;
    return self;
}

- (void) setDistanceDict: (NSDictionary *) inputDict
{
    lineIntervalsDict = [NSDictionary dictionaryWithDictionary:inputDict];
}

- (void) divideLine:(ROI *) roiOPoly
{
    long pointIndex;
	NSMutableArray	*percentLength;
    NSEnumerator    *enumerator;
    
    enumerator = [lineIntervalsDict keyEnumerator];
    id key;
		
    currentSpline		= [roiOPoly splinePoints: scaleValue];
    currentInterPoints	= [[NSMutableDictionary alloc] initWithCapacity:0];
    percentLength		= [self computePercentLength:roiOPoly];
    
    DLog(@"oPoly length = %f cm",[self measureOPolyLength:roiOPoly]);
        
    while (key = [enumerator nextObject]) {
        pointIndex = 0;
        float accumulatedInterval = [[lineIntervalsDict objectForKey:key] floatValue];
        
        // walk the line to next point
        while ([[percentLength objectAtIndex:(pointIndex+1)] floatValue] < accumulatedInterval) {				
            pointIndex +=1;
        }
        
        // select indexed point from spline and add it to array
        [currentInterPoints setObject: [currentSpline objectAtIndex:pointIndex] forKey:key];
    }
}

- (NSArray *) intermediateROIs
{
	int				thisRoiType;
	float			pixelSpacingX,pixelSpacingY;
	NSPoint			thisOrigin;
    
    id              key;
    NSEnumerator    *enumerator;
    
    NSMutableArray *newROIs;
    
    newROIs = [[[NSMutableArray alloc] init] autorelease];
	
	// temporary pointers for creating new ROI
	MyPoint			*thisPoint;
	ROI				*thisROI;
    
	// parameters necessary for initializting a new ROI
	thisRoiType		= t2DPoint;
	pixelSpacingX	= [thePix pixelSpacingX];
	pixelSpacingY	= [thePix pixelSpacingY];
	thisOrigin		= [DCMPix originCorrectedAccordingToOrientation: thePix];
	
    enumerator = [currentInterPoints keyEnumerator];
    while (key = [enumerator nextObject]) {
        thisPoint = [[MyPoint alloc] initWithPoint:[[currentInterPoints objectForKey:key] point]];
		
		// allocate and initialize a new ROI
		thisROI = [[ROI alloc] initWithType: thisRoiType :pixelSpacingX :pixelSpacingY :thisOrigin];
		
        // name the ROI
        thisROI.name = [NSString stringWithString:key];
        
		// move the ROI from the 0,0 to correct coordinates
		thisROI.rect = NSMakeRect(thisPoint.x, thisPoint.y, 0.0, 0.0);
        
		[thisPoint release];
		
        [newROIs addObject:thisROI];
        
		[thisROI release];
    }
    
    return [NSArray arrayWithArray:newROIs];
}

- (NSMutableArray *) computePercentLength: (ROI *) thisROI
{
	long			i,numPoints;
	float			totalLength,thisLength,thisPercent;
	NSMutableArray	*splinePoints,*distanceFromStart,*percentLength;
	
	// do initial calculations
	totalLength			= [self measureOPolyLength:thisROI];
	splinePoints		= [thisROI splinePoints: scaleValue];
	numPoints			= [splinePoints count];
	
	// allocate subsequent arrays
	distanceFromStart	= [[NSMutableArray alloc] initWithCapacity:numPoints];
	percentLength		= [[[NSMutableArray alloc] initWithCapacity:numPoints] autorelease];
	
	// the first element in both cases is 0
	[distanceFromStart addObject:FBOX(0.0)];
	[percentLength addObject:FBOX(0.0)];
	
	// iterate through each point on Open Polygon
	for (i = 1; i < numPoints; i++) {
		// compute length from first point on Open Polygon
		thisLength = [self measureOPolyLength:thisROI fromPointAtIndex:0 toPointAtIndex:i];
		
		// compute what percent this length is of total length
		thisPercent = thisLength/totalLength;
		
		// store computed values to respective matrices
		[distanceFromStart addObject:FBOX(thisLength)];
		[percentLength addObject:FBOX(thisPercent)];
	}
    
    // release object no longer needed
	[distanceFromStart release];
    
	return percentLength;
}

- (float) measureOPolyLength: (ROI *)   roi 
            fromPointAtIndex: (long)    indexPointA 
              toPointAtIndex: (long)    indexPointB
{
	long i;
	float length = 0;
	
	NSMutableArray *splinePoints = [roi splinePoints: scaleValue];
	
	// we can't count up to an index that doesn't exist...
	// ... a negative length should be regarded as invalid
	if (indexPointB > ([splinePoints count] - 1)) {
		return -1;
	}
	
	// accumulate distance between consective points on spline
	for(i = 0; i < indexPointB; i++)
	{
		length += [roi Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:i+1] point]];
	}
    
	return length;
}

- (float) measureOPolyLength: (ROI *) roi
{
	long			lastIndex;
	NSMutableArray	*splinePoints = [roi splinePoints: scaleValue];
	
	lastIndex = [splinePoints count] - 1;
	
	return [self measureOPolyLength: roi fromPointAtIndex: 0 toPointAtIndex: lastIndex];
}

@end
