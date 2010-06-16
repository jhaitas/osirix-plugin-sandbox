//
//  LineDividerFilter.m
//  LineDivider
//
//  Copyright (c) 2010 John Haitas. All rights reserved.
//

#import "LineDividerFilter.h"

@implementation LineDividerFilter

- (void)initPlugin
{
	// OsiriX default scale is 2.0 ...
	// ... we want to program this so that we may change this if we want
	scaleValue			= 2.0;
	tenTwentyIntervals	= [[NSArray alloc] initWithObjects:
								FBOX(.1),FBOX(.2),FBOX(.2),
								FBOX(.2),FBOX(.2),nil];
	
	roiSelectedArray	= [[NSMutableArray alloc] initWithCapacity:0];
	selectedOPolyRois	= [[NSMutableArray alloc] initWithCapacity:0];
	
	
	currentSpline		= [[NSMutableArray alloc] initWithCapacity:0];
	currentInterPoints	= [[NSMutableArray alloc] initWithCapacity:0];
}

- (long)filterImage:(NSString*) menuName
{
		
	[self findSelectedROIs];	
	[self findLineROIs];
	
	// if there are no selected Open Polygons...
	// ... return with error
	if ([selectedOPolyRois count] == 0) {
		return -1;
	}
	
	// Now we know we have selected ROIs ...
	//... some of those are Open Polygon ROIs
	
	[self partitionAllOpenPolyROIs];
	
	NSLog(@"Executed to completion!\n");
	return 0; // No Errors
}

- (void)findSelectedROIs
{
	int				i;
	BOOL			roiSelected			= NO;
	NSMutableArray	*curRoiList			= [[viewerController imageView] curRoiList];
	
	// clear existing array of selected objects
	[roiSelectedArray removeAllObjects];
	
	// iterate through each ROI
	for (i = 0; i < [curRoiList count]; i++) {
		// check if this ROI is selected 
		if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected) {
			// note that there are selected ROIs
			roiSelected = YES;
			
			// add this selected ROI to the array of selected ROIs
			[roiSelectedArray addObject: [curRoiList objectAtIndex:i]];
		}
	}	
	
	// notify user if there are no selected ROI
	if (!roiSelected) {
		// alert the user there are no selected ROIs
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil),
						NSLocalizedString(@"No selected ROIs!", nil), 
						nil, nil, nil);
	}
}

- (void)findLineROIs
{
	int				i;
	BOOL			selectedLines		= NO;
	
	// clear existing array of selected Open Polygon objects
	[selectedOPolyRois removeAllObjects];
	
	// iterate through each selected ROI
	for (i = 0; i < [roiSelectedArray count]; i++) {
		ROI *thisROI = [roiSelectedArray objectAtIndex:i];
		
		// check if this ROI is an Open Polygon...
		// ... defined by at least 3 points
		if (thisROI.type == tOPolygon && [thisROI.points count] > 2) {
			// note that there are lines selected
			selectedLines = YES;
			
			// add this selected line to array of selected lines
			[selectedOPolyRois addObject: [roiSelectedArray objectAtIndex:i]];
		}
	}
	
	// if the current ROI is not an Open Polygon...
	// ... notify the user
	if (!selectedLines) {
		// notify the user through the NSRunAlertPanel		
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil),
						NSLocalizedString(@"No selected Open Polygon ROIs!", nil), 
						nil, nil, nil);
	}
}

- (void)partitionAllOpenPolyROIs
{
	long			i,ii;
	long			numInterPoints,numSplinePoints;
	float			oPolyLength, thisSectionLength;
	ROI				*roiOPoly;
	
	// iterate through each selected Open Polygon ROI
	for (i = 0; i < [selectedOPolyRois count]; i++) {
		roiOPoly			= [selectedOPolyRois objectAtIndex:i];
		currentSpline		= [roiOPoly splinePoints: scaleValue];
		currentInterPoints	= [NSMutableArray arrayWithCapacity:0];
		numSplinePoints		= [currentSpline count];
		numInterPoints		= [tenTwentyIntervals count] - 1;
		oPolyLength			= [self measureOPolyLength:roiOPoly];
		
		NSLog(@"oPoly %d length = %f mm",i,[self measureOPolyLength:roiOPoly]);
		
		for (ii = 0; ii < [tenTwentyIntervals count]; ii++) {
			// determine where on the spline we want to be
			float accumulatedInterval = [self accumulatedIntervalAtIndex:ii];
			
			// calculate the index of the point we want on spline
			int pointIndex			= (numSplinePoints * accumulatedInterval) - 1;
			float expectedLength	= (oPolyLength * accumulatedInterval);
			
			// perform measurement computations
			thisSectionLength		= [self measureOPolyLength:roiOPoly fromPointAtIndex:0 toPointAtIndex: pointIndex];
			float actualInterval	= ((thisSectionLength/oPolyLength));
			float percentError		= fabs(accumulatedInterval - actualInterval)*100.0;
			
			// print information out to console
			NSLog(@"Section %d expectedLength = %f and length = %f is %f%% of total length with a %f%% error",
				  ii,expectedLength,thisSectionLength,actualInterval*100.0,percentError);
			
			// select indexed point from spline and add it to array
			[currentInterPoints addObject: [currentSpline objectAtIndex:pointIndex]];
		}
		
		// add these intermediate points on line as ROIs
		[self addIntermediateROIs];
	}
}

- (void)addIntermediateROIs
{
	
	int				i;
	int				thisRoiType;
	double			pixelSpacingX,pixelSpacingY;
	NSPoint			thisOrigin;
	
	// temporary pointers for creating new ROI
	MyPoint			*thisPoint;
	ROI				*thisROI;
	
	// pointer to current DCMPix in OsiriX
	DCMPix			*thisDCMPix	= [[viewerController imageView] curDCM];

	// parameters necessary for initializting a new ROI
	thisRoiType		= t2DPoint;
	pixelSpacingX	= [thisDCMPix pixelSpacingX];
	pixelSpacingY	= [thisDCMPix pixelSpacingY];
	thisOrigin		= [DCMPix originCorrectedAccordingToOrientation: thisDCMPix];
	
	for (i = 0; i < [currentInterPoints count]; i++) {
		// point to appropriate selected intermediate point
		thisPoint = [[MyPoint alloc] initWithPoint: [[currentInterPoints objectAtIndex:i] point]];
		
		// allocate and initialize a new ROI
		thisROI = [[ROI alloc] initWithType: thisRoiType :pixelSpacingX :pixelSpacingY :thisOrigin];
		
		// move the ROI from the 0,0 to correct coordinates
		thisROI.rect = NSOffsetRect(thisROI.rect, thisPoint.x, thisPoint.y);
		
		// add the new ROI to the current ROI list
		[[[viewerController imageView] curRoiList] addObject:thisROI];
	}
	[thisPoint release];
	[thisROI release];
}

- (float)measureOPolyLength:(ROI *)thisROI fromPointAtIndex:(long)indexPointA toPointAtIndex:(long)indexPointB
{
	long i;
	float length = 0;
	
	NSMutableArray *splinePoints = [thisROI splinePoints: scaleValue];
	
	// we can't count up to an index that doesn't exist...
	// ... a negative length should be regarded as invalid
	if (indexPointB > ([splinePoints count] - 1)) {
		return -1;
	}
	
	// accumulate distance between consective points on spline
	for(i = 0; i < indexPointB; i++)
	{
		length += [thisROI Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:i+1] point]];
	}

	return length;
}

- (float)measureOPolyLength:(ROI *)thisROI
{
	long			lastIndex;
	NSMutableArray	*splinePoints = [thisROI splinePoints: scaleValue];
	
	lastIndex = [splinePoints count] - 1;
	
	return [self measureOPolyLength: thisROI fromPointAtIndex: 0 toPointAtIndex: lastIndex];
}

- (float)accumulatedIntervalAtIndex:(int)index
{
	// instanciate iterator
	int i;
	float accumulator = 0;
	// make sure given index exists
	assert(index <= ([tenTwentyIntervals count] - 1));
	for (i = 0; i <= index; i++) {
		accumulator += [[tenTwentyIntervals objectAtIndex:i] floatValue];
	}
	return accumulator;	
}

@end
