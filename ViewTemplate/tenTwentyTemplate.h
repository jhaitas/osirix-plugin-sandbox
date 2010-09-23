//
//  tenTwentyTemplate.h
//  ViewTemplate
//
//  Created by John Haitas on 9/16/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "StereotaxCoord.H"
#import "parseCSV.h"


@interface tenTwentyTemplate : NSObject {
	StereotaxCoord		*nasion,*inion;
	NSMutableDictionary	*orientation;
	
	// electrodes is an array of ROImm objects
	NSMutableArray	*electrodes;
}
@property (assign)	StereotaxCoord		*nasion;
@property (assign)	StereotaxCoord		*inion;
@property (assign)	NSMutableDictionary	*orientation;
@property (assign)	NSMutableArray		*electrodes;


- (id) initWithNasion: (StereotaxCoord *) thisNasion
			 andInion: (StereotaxCoord *) thisInion;

- (void) computeOrientation;
- (void) computeScalingFactor;
- (void) populateTemplate;
- (void) shiftCoordinates;
- (void) scaleCoordinates;


/*
- (void) registerWithOrigin;
*/

@end
