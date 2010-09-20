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
	NSMutableArray	*electrodes;
}

- (id) initWithOrigin: (ROImm *) thisOrigin;

- (void) populateTemplate;
- (ROImm *) parsedLineToROImm: (NSArray *) thisParsedLine;

@end
