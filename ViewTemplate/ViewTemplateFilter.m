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
												  withZ:location[2]];
			}
		}
	}
	
}

@end
