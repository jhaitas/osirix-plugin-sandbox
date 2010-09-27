//
//  tenTwentyTemplate.h
//  ViewTemplate
//
//  Created by John Haitas on 9/16/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewerController.h"
#import "StereotaxCoord.h"
#import "parseCSV.h"


@interface tenTwentyTemplate : NSObject {
	ViewerController	*viewerController;
	StereotaxCoord		*nasion,*inion;
	StereotaxCoord		*userM1,*userM2;
	double				templateM1M2_AP;
	NSMutableDictionary	*orientation;
	
	// electrodes is an array of ROImm objects
	NSMutableArray	*electrodes;
}
@property (assign)	StereotaxCoord		*nasion;
@property (assign)	StereotaxCoord		*inion;
@property (assign)	NSMutableDictionary	*orientation;
@property (assign)	NSMutableArray		*electrodes;


- (id) initFromViewerController: (ViewerController *) thisViewerController
					 WithNasion: (StereotaxCoord *) thisNasion
					   andInion: (StereotaxCoord *) thisInion;

- (void) computeOrientation;
- (void) populateTemplate;
- (void) shiftCoordinates;
- (void) scaleCoordinatesAP;
- (void) getUserM1andM2;
- (void) scaleCoordinatesML;
- (void) shiftElectrodesUp: (double) mmDistance;

@end
