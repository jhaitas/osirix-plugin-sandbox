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
	name	= [inName retain];
	mmX		= inX;
	mmY		= inY;
	mmZ		= inZ;
	return self;
}

-(double) distanceFrom: (ROImm *) otherROI
{
	double distanceX,distanceY,distanceZ,distanceTotal;
	distanceX = abs(mmX - otherROI.mmX);
	distanceY = abs(mmY - otherROI.mmY);
	distanceZ = abs(mmZ - otherROI.mmZ);
	distanceTotal = sqrt(pow(distanceX,2) + pow(distanceY,2) + pow(distanceZ,2));
	return distanceTotal;
	
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@ X:%0.3f mm Y:%0.3f mm Z:%0.3f mm",name,mmX,mmY,mmZ];
}


@end
