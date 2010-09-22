//
//  StereotaxCoord.m
//  ViewTemplate
//
//  Created by John Haitas on 9/22/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "StereotaxCoord.h"


@implementation StereotaxCoord

@synthesize name;
@synthesize AP,ML,DV;


-(id) initWithName: (NSString *) inName
			withAP: (double) inAP 
			withML: (double) inML
			withDV: (double) inDV
{
	self = [super init];
	[name autorelease];
	
	// assign values to variables
	name	= [NSString stringWithString:inName];
	AP		= inAP;
	ML		= inML;
	DV		= inDV;
	
	// return this instance
	return self;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@\tAP: %0.3fmm\tML: %0.3fmm\tDV: %0.3fmm",name,AP,ML,DV];
}

@end
