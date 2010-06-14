//
//  DistanceROIFilter.m
//  DistanceROI
//
//  Copyright (c) 2010 John Haitas. All rights reserved.
//

#import "DistanceROIFilter.h"

@implementation DistanceROIFilter

- (void) initPlugin
{
	// This gets called when OsiriX loads
	allROIs = [[NSMutableArray alloc] initWithCapacity:0];
	NSLog(@"DistanceROI plugin loaded...\n");
}

- (void) getAllROIs {
	// this method populates allROIs with all ROIs
	// start by clearing allROIs array
	int i,ii;
	
	// clear allROIs array
	[allROIs removeAllObjects];
	
	// get both dcmPixList and dcmRoiList
	NSArray *pixList = [viewerController pixList];
	NSArray *roiList = [viewerController roiList];

	// go through all ROI lists
	for (i = 0; i < [roiList count]; i++) {
		DCMPix *pix = [pixList objectAtIndex:i];
		NSArray *thisPixRoiList = [roiList objectAtIndex:i];
		
		// go through each ROI in this list
		for (ii = 0; ii < [thisPixRoiList count]; ii++) {
			// Pointer reassigned to each object in the list
			ROI *roi = [thisPixRoiList objectAtIndex:ii];
			NSMutableArray *roiPoints = [ roi points ];
			NSPoint roiCenterPoint;
			
			// calc center of the ROI
			if ( [ roi type ] == t2DPoint ) {
				// ROI has a bug which causes miss-calculating center of 2DPoint roi
				roiCenterPoint = [ [ roiPoints objectAtIndex: 0 ] point ];
			} else {
				roiCenterPoint = [ roi centroid ];
			}
			
			// declare 3 element array to store XYZ coordinates for this point
			float location[3];
			
			// convert pixel values to mm values
			[pix convertPixX:roiCenterPoint.x pixY:roiCenterPoint.y toDICOMCoords:location];
			
			// instanciate a ROImm object and add it to the allROIs NSMutableArray
			[allROIs addObject: [[ROImm alloc] initWithName:roi.name withX:location[0] withY:location[1] withZ:location[2]]];
		}
	}
}

- (void) printAllDistances
{
	int i,ii;
	// loop through all ROIs in list except the last one
	for (i = 0; i < ([allROIs count]-1); i++) {
		ROImm *thisROImm = [allROIs objectAtIndex:i];
		NSLog(@"%@ distance from:\n",thisROImm);
		
		// loop through remaining ROIs in list
		for (ii = (i + 1); ii < [allROIs count]; ii++) {
			ROImm *otherROImm = [allROIs objectAtIndex:ii];
			NSLog(@"\t%@: %fmm\n",otherROImm.name,[thisROImm distanceFrom: otherROImm]);
		}
	}
}

- (void) printAllROIs
{
	// loop through all ROIs
	for (ROImm *thisROImm in allROIs) {
		NSLog(@"%@\n",thisROImm);
	}
}

- (long) filterImage:(NSString*) menuName
{
	// entry point for plugin
	[self getAllROIs];
	[self printAllROIs];
	[self printAllDistances];
	return 0; // No Errors
}

-(void)dealloc
{
	[super dealloc];
}
@end
