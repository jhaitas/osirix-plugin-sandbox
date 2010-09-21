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
	
	[self findOriginROI];
	
	myTenTwenty = [[tenTwentyTemplate alloc] initWithOrigin:originROI];
	
	[self addElectrodes];
	
	NSLog(@"executed method\n");
	return 0;
}

- (void) findOriginROI
{
	int				i,ii;
	float			location[3];
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
			if ([selectedROI.name isEqualToString:@"origin"]) {
				NSLog(@"Found origin in slice %d\n",i);
				originROIslice = i;
				
				
				NSMutableArray *roiPoints = [ selectedROI points ];
				NSPoint roiCenterPoint;
				
				// calc center of the ROI
				if ( [ selectedROI type ] == t2DPoint ) {
					// ROI has a bug which causes miss-calculating center of 2DPoint roi
					roiCenterPoint = [ [ roiPoints objectAtIndex: 0 ] point ];
				} else {
					roiCenterPoint = [ selectedROI centroid ];
				}
				
				// convert pixel values to mm values
				[thisPix convertPixX:roiCenterPoint.x pixY:roiCenterPoint.y toDICOMCoords:location];
				
				NSLog(@"Origin coordinates (x,y,z) = (%.3f,%.3f,%.3f)\n",location[0],location[1],location[2]);
				originROI = [[ROImm alloc] initWithName:selectedROI.name
												  withX:location[0] 
												  withY:location[1] 
												  withZ:location[2]			];
			}
		}
	}
	
}


- (void)addElectrodes
{
	int				thisRoiType;
	double			pixelSpacingX,pixelSpacingY;
	double			dicomCoords[3],sliceCoords[3];
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
	
	for (ROImm *thisElectrode in myTenTwenty.electrodes) {
		// allocate and initialize a new ROI
		thisROI = [[ROI alloc] initWithType:thisRoiType
										   :pixelSpacingX
										   :pixelSpacingY
										   :thisOrigin];
		
		// get DICOM coordinates from current electrode
		[thisElectrode dicomCoords:dicomCoords];
		
		[thisDCMPix convertDICOMCoordsDouble:dicomCoords toSliceCoords:sliceCoords];
/*		
		NSLog(@"Converted (%3.3f,%3.3f,%3.3f) to  (%3.3f,%3.3f,%3.3f) \n",
				dicomCoords[0],dicomCoords[1],dicomCoords[2],
				sliceCoords[0],sliceCoords[1],sliceCoords[2]				);
*/		
		// move the ROI from the 0,0 to correct coordinates
		thisROI.rect = NSOffsetRect(thisROI.rect, sliceCoords[2], sliceCoords[1]);
		
		thisROI.name = [NSString stringWithString:thisElectrode.name];
				
		// add the new ROI to the current ROI list
		[[[viewerController imageView] curRoiList] addObject:thisROI];
	}
}

@end
