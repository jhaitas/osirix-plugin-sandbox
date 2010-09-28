//
//  StereotaxCoord.m
//  ViewTemplate
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "StereotaxCoord.h"


@implementation StereotaxCoord

@synthesize name;
@synthesize AP,ML,DV;


- (id) initWithName: (NSString *) inName
			 withAP: (float) inAP 
			 withML: (float) inML
			 withDV: (float) inDV
{
    if ((self = [super init])) {
		[name autorelease];
		
		// assign values to variables
		name	= [NSString stringWithString:inName];
		AP		= inAP;
		ML		= inML;
		DV		= inDV;
	}
	// return this instance
	return self;
}

- (StereotaxCoord *) copy
{
	return [[StereotaxCoord alloc] initWithName:[NSString stringWithString:name]
										 withAP:AP
										 withML:ML
										 withDV:DV									];
}

// method for remapping coordinates after orientation has been determined
- (void) remapWithOrientation: (NSMutableDictionary *) theOrientation
{
	double tmpAP,tmpML,tmpDV;
	
	tmpAP = AP;
	tmpML = ML;
	tmpDV = DV;
	
	switch ([[theOrientation objectForKey:@"AP"] intValue]) {
		case 0:
			AP = tmpAP;
			break;
		case 1:
			AP = tmpML;
			break;
		case 2:
			AP = tmpDV;
			break;
		default:
			NSLog(@"WARNING: unknown value for AP key\n");
			break;
	}
	
	switch ([[theOrientation objectForKey:@"ML"] intValue]) {
		case 0:
			ML = tmpAP;
			break;
		case 1:
			ML = tmpML;
			break;
		case 2:
			ML = tmpDV;
			break;
		default:
			NSLog(@"WARNING: unknown value for ML key\n");
			break;
	}
	
	switch ([[theOrientation objectForKey:@"DV"] intValue]) {
		case 0:
			DV = tmpAP;
			break;
		case 1:
			DV = tmpML;
			break;
		case 2:
			DV = tmpDV;
			break;
		default:
			NSLog(@"WARNING: unknown value for DV key\n");
			break;
	}
}

// return is contained in 3 element double array named here 'dicomCoords'
- (void) returnDICOMCoords: (float *) dicomCoords
		   withOrientation: (NSMutableDictionary *) theOrientation
{
	dicomCoords[[[theOrientation objectForKey:@"AP"] intValue]] = AP;
	dicomCoords[[[theOrientation objectForKey:@"ML"] intValue]] = ML;
	dicomCoords[[[theOrientation objectForKey:@"DV"] intValue]] = DV;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@\tAP: %0.3fmm\tML: %0.3fmm\tDV: %0.3fmm",name,AP,ML,DV];
}

@end
