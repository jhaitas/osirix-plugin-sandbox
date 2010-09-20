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
	
	// allocate and inititalize electrodes array
	electrodes = [[NSMutableArray alloc] init];
	
	// set origin location
	originROI = [[ROImm alloc] initWithName:thisOrigin.name
									  withX:thisOrigin.mmX
									  withY:thisOrigin.mmY
									  withZ:thisOrigin.mmZ	];
	
	[self populateTemplate];
	
	// return this instance
	return self;
}

- (void) populateTemplate
{
	int i,arrayOffset;
	
	// Identify plugin Bundle
	NSString *name			= [[NSString alloc] initWithString:@"zeroedTemplate"];
	NSString *ext			= [[NSString alloc] initWithString:@"csv"];
	NSString *path			= [[NSBundle bundleWithIdentifier:@"edu.vanderbilt.viewtemplate"] resourcePath];
		
	NSString *fullFilename	= [[NSString alloc] initWithFormat:@"%@/%@.%@",path,name,ext];
		
	CSVParser		*myCSVParser		= [[CSVParser alloc] init];
	NSMutableArray	*parsedElectrodes;
	
	[myCSVParser setDelimiter:','];
	if ([myCSVParser openFile:fullFilename]) {
		NSLog(@"Success opening %@\n",fullFilename);
		parsedElectrodes = [myCSVParser parseFile];
		NSLog(@"%d csv lines parsed.\n",[parsedElectrodes count]);
	} else {
		NSLog(@"Failed to open %@\n",fullFilename);
	}
	
	// start from object at index 2 ...
	// ... index 0 contains headers ...
	// ... index 1 contains origin
	arrayOffset = 2;
	for (i = arrayOffset; i < [parsedElectrodes count]; i++) {
		NSArray *thisElectrode = [parsedElectrodes objectAtIndex:i];
		[electrodes insertObject:[self parsedLineToROImm:thisElectrode]
						 atIndex:i-arrayOffset							];
	}
	
	for (i = 0; i < [electrodes count]; i++) {
		NSLog(@"%@\n",[electrodes objectAtIndex:i]);
	}
	
	[myCSVParser autorelease];
	[name autorelease];
	[ext autorelease];
/*
	[path autorelease];
	[fullFilename autorelease];
*/
}

- (ROImm *) parsedLineToROImm: (NSArray *) thisParsedLine
{
	ROImm	*thisROImm;
	thisROImm = [[ROImm alloc] initWithName:[[NSString alloc] initWithString:[thisParsedLine objectAtIndex:0]]
										withX:[[thisParsedLine objectAtIndex:2] doubleValue]
										withY:[[thisParsedLine objectAtIndex:1] doubleValue]
										withZ:[[thisParsedLine objectAtIndex:3] doubleValue]					];
	return thisROImm;
}

@end
