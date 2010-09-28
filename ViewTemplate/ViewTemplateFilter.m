//
//  ViewTemplateFilter.m
//  ViewTemplate
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "ViewTemplateFilter.h"

@implementation ViewTemplateFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
	NSLog(@"Starting Plugin\n");
	
	// there should be an ROI named 'nasion' and 'inion'
	[self findUserInput];
	
	// pass the nasion and inion to the tenTwentyTemplate
	myTenTwenty = [[tenTwentyTemplate alloc] initFromViewerController:viewerController
														   WithNasion:nasion
															 andInion:inion				];
	
	// place electrodes on MRI
	[self addElectrodes];
	
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
													   withDV:location[2]			];
				foundNasion = TRUE;
			}
			// check if this ROI is named 'inion'
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
	
	// make sure that both 'nasion' and 'inion' were located
	if (!foundNasion || !foundInion) {
		// notify the user through the NSRunAlertPanel		
		NSRunAlertPanel(NSLocalizedString(@"Plugin Error", nil),
						NSLocalizedString(@"Unable to locate 'nasion' and 'inion'!", nil), 
						nil, nil, nil);
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
				 toDICOMCoords:location			];
	NSLog(@"%@ coordinates (AP,ML,DV) = (%.3f,%.3f,%.3f)\n",thisROI.name,location[0],location[1],location[2]);
}

- (void) addElectrodes
{
	int				thisRoiType,bestSlice;
	double			pixelSpacingX,pixelSpacingY;
	float			dicomCoords[3],sliceCoords[3];
	
	// temporary pointers for creating new ROI
	ROI				*thisROI;
	
	// pointer to current DCMPix in OsiriX
	DCMPix			*thisDCMPix	= [[viewerController imageView] curDCM];
	
	// parameters necessary for initializting a new ROI
	thisRoiType		= t2DPoint;
	pixelSpacingX	= [thisDCMPix pixelSpacingX];
	pixelSpacingY	= [thisDCMPix pixelSpacingY];
		
	for (StereotaxCoord *thisElectrode in myTenTwenty.electrodes) {
		// get DICOM coords which we will convert to slice coords
		[thisElectrode returnDICOMCoords:dicomCoords withOrientation:myTenTwenty.orientation];
		
		// find nearest slice
		bestSlice = [DCMPix nearestSliceInPixelList:[[viewerController imageView] dcmPixList]
									withDICOMCoords:dicomCoords
										sliceCoords:sliceCoords									];
		
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
		[[[[viewerController imageView] dcmRoiList] objectAtIndex:bestSlice] addObject:thisROI];
		
		// lower the electrode to the surface of the skull
		[self lowerElectrode:thisROI inSlice:[[[viewerController imageView] dcmPixList] objectAtIndex:bestSlice]];
		
		[thisROI release];
	}
	// update screen
	[viewerController updateImage:self];
}

- (void) lowerElectrode: (ROI *) thisROI inSlice: (DCMPix *) thisSlice
{
	int		indexDV;
	float	currentPixelMean;
	double	pixelSpacingX,pixelSpacingY;
	float	dicomCoords[3],sliceCoords[3];
	float	minScalpValue,maxSkullValue;
	BOOL	foundScalp,foundSkull;
	NSPoint	roiPosition;
	NSPoint	offsetShift;
	
	// initialize values
	indexDV				= [[myTenTwenty.orientation objectForKey:@"DV"] intValue];
	foundScalp			= NO;
	foundSkull			= NO;
	currentPixelMean	= -1.0;
	pixelSpacingX		= [thisSlice pixelSpacingX];
	pixelSpacingY		= [thisSlice pixelSpacingY];
	
	// these values should be made user configurable in the future
	minScalpValue = 45.0;
	maxSkullValue = 30.0;
	
	// select this ROI (prerequisite for [ROI roiMove: :] method)
	[thisROI setROIMode: ROI_selected];
	
	if (indexDV == 2) {
		NSLog(@"DV index indicates DV goes across slices... no implementation for this yet\n");
		return;
	}

	// drop till we locate the scalp
	while (!foundScalp) {
		roiPosition = thisROI.rect.origin;
		
		// get DICOM coordinates (in mm)
		[thisSlice convertPixX:roiPosition.x pixY:roiPosition.y toDICOMCoords:dicomCoords];
		
		// drop point .1 mm on DV plane
		dicomCoords[indexDV] -= .1;
		
		// convert back to slice coords
		[thisSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
		
		// determine how coordinates should be shifted
		offsetShift.x = (sliceCoords[0] / pixelSpacingX) - roiPosition.x;
		offsetShift.y = (sliceCoords[1] / pixelSpacingY) - roiPosition.y;
		
		// shift the ROI
		[thisROI roiMove:offsetShift :TRUE];
 		
		// determine current pixel mean
		[thisSlice computeROI:thisROI :&currentPixelMean :NULL :NULL :NULL :NULL];
		
		// detect if we have found the scalp
		if (currentPixelMean > minScalpValue) {
			foundScalp = YES;
		}
		
		// be sure we haven't fallen to the bottom of the slice
		if (!(thisROI.rect.origin.x >= 0) || !(thisROI.rect.origin.y >= 0)) {
			NSLog(@"%@ falling off slice!!!\n",thisROI.name);
			break;
		}
	}
	
	// drop till we locate the skull
	while (!foundSkull) {
		roiPosition = thisROI.rect.origin;
		
		// get DICOM coordinates (in mm)
		[thisSlice convertPixX:roiPosition.x pixY:roiPosition.y toDICOMCoords:dicomCoords];
		
		// drop point .01 mm on DV plane
		dicomCoords[indexDV] -= .01;
		
		// convert back to slice coords
		[thisSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
		
		// determine how coordinates should be shifted
		offsetShift.x = (sliceCoords[0] / pixelSpacingX) - roiPosition.x;
		offsetShift.y = (sliceCoords[1] / pixelSpacingY) - roiPosition.y;
		
		// shift the ROI
		[thisROI roiMove:offsetShift :TRUE];
 		
		// determine current pixel mean
		[thisSlice computeROI:thisROI :&currentPixelMean :NULL :NULL :NULL :NULL];
		
		// detect if we have found the skull
		if (currentPixelMean < maxSkullValue) {
			foundSkull = YES;
		}
		
		// be sure we haven't fallen to the bottom of the slice
		if (!(thisROI.rect.origin.x >= 0) || !(thisROI.rect.origin.y >= 0)) {
			NSLog(@"%@ falling off slice!!!\n",thisROI.name);
			break;
		}
	}
	
	// put this ROI back to sleep
	[thisROI setROIMode: ROI_sleep];

}

@end
