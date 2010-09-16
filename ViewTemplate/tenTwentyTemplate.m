//
//  tenTwentyTemplate.m
//  ViewTemplate
//
//  Created by John Haitas on 9/16/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "tenTwentyTemplate.h"


@implementation tenTwentyTemplate

- (id) initWithOrigin: (ROImm *) thisOrigin
{
	self = [super init];
	[originROI autorelease];
	[electrodes autorelease];
	
	// set origin location
	originROI = [[ROImm alloc] initWithName:thisOrigin.name
									  withX:thisOrigin.mmX
									  withY:thisOrigin.mmY
									  withZ:thisOrigin.mmZ	];
	
	// return this instance
	return self;
}

- (void) populateTemplate
{
	electrodes = [[NSMutableArray alloc] init];
}

@end
