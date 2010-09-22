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
	StereotaxCoord	*stereotaxOrigin;
	
	// electrodes is an array of ROImm objects
	NSMutableArray	*electrodes;
}
@property (assign)	StereotaxCoord *stereotaxOrigin;
@property (assign)	NSMutableArray *electrodes;

- (id) initWithOrigin: (StereotaxCoord *) thisOrigin;

- (void) populateTemplate;

/*
- (void) registerWithOrigin;
*/

@end
