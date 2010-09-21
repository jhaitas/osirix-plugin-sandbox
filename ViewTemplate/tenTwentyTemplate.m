//
//  tenTwentyTemplate.m
//  ViewTemplate
//
//  Created by John Haitas on 9/16/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "tenTwentyTemplate.h"


@implementation tenTwentyTemplate

@synthesize originROI;
@synthesize electrodes;

- (id) initWithOrigin: (ROImm *) thisOrigin
{
	self = [super init];
//	[originROI autorelease];
//	[electrodes autorelease];
	
	// allocate and inititalize electrodes array
	electrodes = [[NSMutableArray alloc] init];
	
	// set origin location
	originROI = [[ROImm alloc] initWithName:thisOrigin.name
									  withX:thisOrigin.mmX
									  withY:thisOrigin.mmY
									  withZ:thisOrigin.mmZ	];
	
	[self populateTemplate];
	
	[self registerWithOrigin];
	
	// return this instance
	return self;
}

- (void) populateTemplate
{
	int i,arrayOffset;
	
	// Identify plugin Bundle
	NSString *name			= [NSString stringWithString:@"zeroedTemplate"];
	NSString *ext			= [NSString stringWithString:@"csv"];
	NSString *path			= [[NSBundle bundleWithIdentifier:@"edu.vanderbilt.viewtemplate"] resourcePath];
		
	NSString *fullFilename	= [NSString stringWithFormat:@"%@/%@.%@",path,name,ext];
		
	CSVParser		*myCSVParser		= [[CSVParser alloc] init];
	NSMutableArray	*parsedElectrodes;
	
	[myCSVParser setDelimiter:','];
	if ([myCSVParser openFile:fullFilename]) {
		NSLog(@"Success opening %@\n",fullFilename);
		parsedElectrodes = [myCSVParser parseFile];
		NSLog(@"%d csv lines parsed.\n",[parsedElectrodes count]);
	} else {
		NSLog(@"Failed to open %@\n",fullFilename);
		return;
	}

	// start from object at index 2 ...
	// ... index 0 contains headers ...
	// ... index 1 contains origin
	arrayOffset = 2;
	for (i = arrayOffset; i < [parsedElectrodes count]; i++) {
		ROImm *tmpROImm = [ROImm alloc];
		[self parsedLine:[parsedElectrodes objectAtIndex:i] toROImm: tmpROImm];
		[electrodes addObject:tmpROImm];
		[tmpROImm release];
	}
	
	[myCSVParser closeFile];
	[myCSVParser release];
}

- (void) parsedLine: (NSArray *) thisParsedLine toROImm: (ROImm *) thisROImm
{
	[thisROImm initWithName:[[NSString alloc] initWithString:[thisParsedLine objectAtIndex:0]]
					 withX:[[thisParsedLine objectAtIndex:2] doubleValue]
					 withY:[[thisParsedLine objectAtIndex:1] doubleValue]
					 withZ:[[thisParsedLine objectAtIndex:3] doubleValue]						];
}

- (void) registerWithOrigin
{
	int i;
	ROImm	*tmpROImm;
	
	for (i = 0; i < [electrodes count]; i++)
	{
		tmpROImm = [electrodes objectAtIndex:i];
		tmpROImm.mmX += originROI.mmX;
		tmpROImm.mmY += originROI.mmY;
		tmpROImm.mmZ += originROI.mmZ;
		NSLog(@"%@\n",[electrodes objectAtIndex:i]);
	}
}

@end
