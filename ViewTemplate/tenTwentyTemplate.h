//
//  tenTwentyTemplate.h
//  ViewTemplate
//
//  Created by John Haitas on 9/16/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ROImm.h"
#import "parseCSV.h"


@interface tenTwentyTemplate : NSObject {
	ROImm			*originROI;
	
	// electrodes is an array of ROImm objects
	NSMutableArray	*electrodes;
}
@property (assign)	ROImm *originROI;
@property (assign)	NSMutableArray *electrodes;

- (id) initWithOrigin: (ROImm *) thisOrigin;

- (void) populateTemplate;

- (void) parsedLine: (NSArray *) thisParsedLine toROImm: (ROImm *) tmpROImm;

- (void) registerWithOrigin;

@end
