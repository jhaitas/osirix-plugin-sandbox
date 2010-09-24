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
	
	[self determineSlicePlane];
	
	// there should be an ROI named 'origin' in current DCMView
	[self findUserInput];
	
	// pass the nasion and inion to the tenTwentyTemplate
	myTenTwenty = [[tenTwentyTemplate alloc] initWithNasion:nasion andInion:inion];
	
	// place electrodes on MRI
	[self addElectrodes];
	
	NSLog(@"executed method\n");
	return 0;
}

- (void) determineSlicePlane
{
	// for now we will assume the slice plane is 0 ...
	// ... this needs to be verified
	slicePlane = 0;
/*
	int		i;
	double	locationSet1[3],locationSet2[3],diffSet[3];
	DCMPix	*pix1,*pix2;
	
	pix1 = [[viewerController pixList] objectAtIndex:0];
	pix2 = [[viewerController pixList] objectAtIndex:1];
	
	[pix1 convertPixDoubleX:0.0 pixY:0.0 toDICOMCoords:locationSet1];
	[pix2 convertPixDoubleX:0.0 pixY:0.0 toDICOMCoords:locationSet2];
	
	for (i = 0; i < 3; i++) {
		diffSet[i] = locationSet2[i] - locationSet1[i];
	}
	
	NSLog(@"diffSet = (%f,%f,%f)\n",diffSet[0],diffSet[1],diffSet[2]);
 */
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
	float			thisPixelMean;
	
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
		
//		NSLog(@"DICOM coords = (%.3f,%.3f,%.3f)\n",dicomCoords[0],dicomCoords[1],dicomCoords[2]);
		
		// find nearest slice
		bestSlice = [DCMPix nearestSliceInPixelList:[[viewerController imageView] dcmPixList]
									withDICOMCoords:dicomCoords
										sliceCoords:sliceCoords									];
		
		// allocate and initialize a new ROI
		thisROI = [[ROI alloc] initWithType:thisRoiType
										   :pixelSpacingX
										   :pixelSpacingY
										   :NSMakePoint(0.0, 0.0)];
		
		
		thisROI.rect = NSOffsetRect(thisROI.rect, sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY);
		
		thisROI.name = [NSString stringWithString:thisElectrode.name];
				
		// add the new ROI to the correct ROI list
		[[[[viewerController imageView] dcmRoiList] objectAtIndex:bestSlice] addObject:thisROI];
		
		// next two lines demonstrate how to determine the pixel value at the given ROI ...
		// ... this will be used to determine if ROI is correctly placed
		[[[[viewerController imageView] dcmPixList] objectAtIndex:bestSlice] computeROI:thisROI :&thisPixelMean :NULL :NULL :NULL :NULL];
		NSLog(@"%@ value = %f\n",thisROI.name,thisPixelMean);
		
		[thisROI release];
	}
	// update screen
	[viewerController updateImage:self];
}

@end
