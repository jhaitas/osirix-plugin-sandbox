//
//  tenTwentyTemplate.m
//  ViewTemplate
//
//  Created by John Haitas on 9/16/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "tenTwentyTemplate.h"


@implementation tenTwentyTemplate

@synthesize stereotaxOrigin;
@synthesize electrodes;

- (id) initWithOrigin: (StereotaxCoord *) thisOrigin
{
	self = [super init];
//	[originROI autorelease];
//	[electrodes autorelease];
	
	// allocate and inititalize electrodes array
	electrodes = [[NSMutableArray alloc] init];
	
	// set origin location
	stereotaxOrigin = [[StereotaxCoord alloc] initWithName:thisOrigin.name
									  withAP:thisOrigin.AP
									  withML:thisOrigin.ML
									  withDV:thisOrigin.DV	];
	
	// return this instance
	return self;
}

- (void) populateTemplate
{
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
	[parsedElectrodes removeObjectAtIndex:0];
	[parsedElectrodes removeObjectAtIndex:1];
	for (id thisParsedLine in parsedElectrodes) {
		StereotaxCoord *tmpElectrode = [StereotaxCoord alloc];
		[tmpElectrode initWithName:[[NSString alloc] initWithString:[thisParsedLine objectAtIndex:0]]
							 withAP:[[thisParsedLine objectAtIndex:2] doubleValue]
							 withML:[[thisParsedLine objectAtIndex:1] doubleValue]
							 withDV:[[thisParsedLine objectAtIndex:3] doubleValue]						];
		[electrodes addObject:tmpElectrode];
	}
	
	[myCSVParser closeFile];
	[myCSVParser release];
}

/*
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
*/

@end
