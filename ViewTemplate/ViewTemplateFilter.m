//
//  ViewTemplateFilter.m
//  ViewTemplate
//
//  Copyright (c) 2010 John. All rights reserved.
//

#import "ViewTemplateFilter.h"

@implementation ViewTemplateFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
	NSLog(@"Starting Plugin\n");
	
	// there should be an ROI named 'origin' in current DCMView
	[self findUserInput];
	
	[self computeOrientation];
	
	// pass the origin to the tenTwentyTemplate
//	myTenTwenty = [[tenTwentyTemplate alloc] initWithOrigin:stereotaxOrigin];
	// read in template from CSV file
//	[myTenTwenty populateTemplate];
	// shift electrodes with respect to origin
//	[myTenTwenty registerWithOrigin];
	
	// place electrodes on MRI
//	[self addElectrodes];
	
	NSLog(@"executed method\n");
	return 0;
}

- (void) findUserInput
{
	int				i,ii;
	double			location[3];
	ROI				*selectedROI;	
	
	NSArray			*pixList;
	NSArray			*roiList;
	NSArray			*thisRoiList;
	DCMPix			*thisPix;
	
	pixList = [viewerController pixList];
	roiList = [viewerController roiList];
	
	for (i = 0; i < [roiList count]; i++) {
		thisRoiList = [roiList objectAtIndex:i];
		thisPix = [pixList objectAtIndex:i];
		for (ii = 0; ii < [thisRoiList count]; ii++) {
			selectedROI = [thisRoiList objectAtIndex:ii];
			if ([selectedROI.name isEqualToString:@"nasion"]) {
				[self getROI:selectedROI fromPix:thisPix toCoords:location];
				nasion = [[StereotaxCoord alloc] initWithName:selectedROI.name
													   withAP:location[0] 
													   withML:location[1] 
													   withDV:location[2]			];
				foundNasion = TRUE;
			}
			if ([selectedROI.name isEqualToString:@"inion"]) {
				[self getROI:selectedROI fromPix:thisPix toCoords:location];
				inion = [[StereotaxCoord alloc] initWithName:selectedROI.name
													   withAP:location[0] 
													   withML:location[1] 
													   withDV:location[2]			];
				foundInion = TRUE;
			}
		}
	}
	
	if (!foundNasion || !foundInion) {
		// notify the user through the NSRunAlertPanel		
		NSRunAlertPanel(NSLocalizedString(@"Plugin Error", nil),
						NSLocalizedString(@"Unable to locate 'nasion' and 'inion'!", nil), 
						nil, nil, nil);
	}
	
}

// coordinates natively in (x,y,z) ...
// ... greatest difference between nasion and inion should be AP
// ... ML should be same in nasion and inion
// ... DV should be smaller difference than AP
//
// no doubt there is a more elegant way to do this
- (void) computeOrientation
{
	int				i,ii,firstIndex,secondIndex;
	double			thisDouble,firstDouble,secondDouble;
	int				indexAP,indexML,indexDV;
	NSNumber		*diffAP,*diffML,*diffDV;
	NSMutableArray	*diff,*orientation;
	
	diffAP	= [NSNumber numberWithDouble:(nasion.AP - inion.AP)];
	diffML	= [NSNumber numberWithDouble:(nasion.ML - inion.ML)];
	diffDV	= [NSNumber numberWithDouble:(nasion.DV - inion.DV)];
	
	diff		= [[NSMutableArray alloc] initWithObjects:diffAP,diffML,diffDV,nil];
	orientation	= [[NSMutableArray alloc] initWithCapacity:3];
	
	// first we identify and eliminate ML
	for (i = 0; i < [diff count]; i++) {
		thisDouble = [[diff objectAtIndex:i] doubleValue];
		if (thisDouble == 0.0) {
			// found ML ... store its index
			indexML = i;
		}
	}
	
	// now find which magnitude is greater between remaining diffs
	for (i = 0; i < ([diff count] - 1); i++) {
		// ignore item identified as ML
		if (i == indexML) continue;
		firstDouble = [[diff objectAtIndex:i] doubleValue];
		firstIndex = i;
		for (ii = i + 1; ii < [diff count]; ii++) {
			// ignore item identified as ML
			if (ii == indexML) continue;
			secondDouble = [[diff objectAtIndex:ii] doubleValue];
			secondIndex = ii;
		}
	}
	
	NSLog(@"firstIndex = %d\n",firstIndex);
	NSLog(@"secondIndex = %d\n",secondIndex);
	
	if (fabs(firstDouble) > fabs(secondDouble)) {
		indexAP = firstIndex;
		indexDV = secondIndex;
	} else {
		indexAP = secondIndex;
		indexDV = firstIndex;
	}
	
	NSLog(@"%@\n",orientation);		
	
	NSLog(@"ML identified at index %d\n",indexML);
	
	NSLog(@"diffAP = %f\n",[diffAP doubleValue]);
	NSLog(@"diffML = %f\n",[diffML doubleValue]);
	NSLog(@"diffDV = %f\n",[diffDV doubleValue]);
	
	NSLog(@"(AP,ML,DV) are mapped as (%d,%d,%d)\n",indexAP,indexML,indexDV);
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
				 toDICOMCoords:location			];
	NSLog(@"%@ coordinates (AP,ML,DV) = (%.3f,%.3f,%.3f)\n",thisROI.name,location[0],location[1],location[2]);
}

- (void) addElectrodes
{
	int				thisRoiType;
	double			pixelSpacingX,pixelSpacingY;
	NSPoint			thisOrigin;
	
	// temporary pointers for creating new ROI
	ROI				*thisROI;
	
	// pointer to current DCMPix in OsiriX
	DCMPix			*thisDCMPix	= [[viewerController imageView] curDCM];
	
	// parameters necessary for initializting a new ROI
	thisRoiType		= t2DPoint;
	pixelSpacingX	= [thisDCMPix pixelSpacingX];
	pixelSpacingY	= [thisDCMPix pixelSpacingY];
	thisOrigin		= [DCMPix originCorrectedAccordingToOrientation: thisDCMPix];
	
	for (StereotaxCoord *thisElectrode in myTenTwenty.electrodes) {
		// allocate and initialize a new ROI
		thisROI = [[ROI alloc] initWithType:thisRoiType
										   :pixelSpacingX
										   :pixelSpacingY
										   :thisOrigin];
		
		thisROI.name = [NSString stringWithString:thisElectrode.name];
				
		// add the new ROI to the current ROI list
		[[[viewerController imageView] curRoiList] addObject:thisROI];
	}
}

@end
