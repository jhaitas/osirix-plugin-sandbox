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
	// initialize plugin
	allROIs = [[NSMutableArray alloc] initWithCapacity:0];
	NSLog(@"DistanceROI plugin loaded...\n");
}

- (void) getAllROIs {
	// this method populates allROIs with all ROIs
	int currentList,currentROI;
	currentList = 0;
	for( NSArray *thisRoiList in [[viewerController imageView] dcmRoiList]) {
		currentList++;
		currentROI = 0;
		NSLog(@"List item %3d\n",currentList);
		for (ROI *thisROI in thisRoiList) {
			currentROI++;
			[allROIs addObject:thisROI];
			NSLog(@"\tROI %d\n",currentROI);
		}
	}
	NSLog(@"Collected %d ROIs\n",[allROIs count]);
}

- (void) printEachROI {
	// this method prints out point values for each ROI
	int counter = 0;
	for (ROI *thisROI in allROIs) {
		counter++;
		NSLog(@"ROI %d: %@ = %@\n",counter,[thisROI name],[thisROI points]);

	}
}

- (long) filterImage:(NSString*) menuName
{
	// entry point for plugin
	[self getAllROIs];
	[self printEachROI];
	return 0; // No Errors
}

-(void)dealloc
{
	// cleanup
	[allROIs release];
	[super dealloc];
}
@end
