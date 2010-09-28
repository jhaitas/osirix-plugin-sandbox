//
//  tenTwentyTemplate.h
//  ViewTemplate
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StereotaxCoord.h"
#import "parseCSV.h"


@interface tenTwentyTemplate : NSObject {
	StereotaxCoord		*nasion,*inion;
	double				templateM1M2_AP;
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
- (void) populateTemplate;

- (StereotaxCoord *) getElectrodeWithName: (NSString *) theName;
- (void) shiftCoordinates;
- (void) scaleCoordinatesAP;
- (void) scaleCoordinatesMLwithM1: (StereotaxCoord *) userM1
							andM2: (StereotaxCoord *) userM2;
- (void) shiftElectrodesUp: (double) mmDistance;

@end
