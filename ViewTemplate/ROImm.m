//
//  ROImm.m
//  DistanceROI
//
//  Created by John Haitas on 6/9/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "ROImm.h"


@implementation ROImm

@synthesize name;
@synthesize mmX,mmY,mmZ;

-(id) initWithName: (NSString *) inName
			   withX: (double) inX 
			   withY: (double) inY 
			   withZ: (double) inZ
{
	self = [super init];
	[name autorelease];
	
	// assign values to variables
	name	= [inName retain];
	mmX		= inX;
	mmY		= inY;
	mmZ		= inZ;

	// return this instance
	return self;
}

-(double) distanceFrom: (ROImm *) otherROI
{
	// create variables to store intermediate values
	double distanceX,distanceY,distanceZ,distanceTotal;
	
	// calculate the distance on each plane
	distanceX = fabs(mmX - otherROI.mmX);
	distanceY = fabs(mmY - otherROI.mmY);
	distanceZ = fabs(mmZ - otherROI.mmZ);
	
	// apply the distance formula
	distanceTotal = sqrt(pow(distanceX,2) + pow(distanceY,2) + pow(distanceZ,2));
	
	// return the total distance between the ROIs
	return distanceTotal;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@\tX: %0.3fmm\tY: %0.3fmm\tZ: %0.3fmm",name,mmX,mmY,mmZ];
}


@end
