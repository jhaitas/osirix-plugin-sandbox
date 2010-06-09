//
//  ROImm.h
//  DistanceROI
//
//  Created by John Haitas on 6/9/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ROImm : NSObject {
	NSString * name;
	double mmX,mmY,mmZ;
}
@property(assign) NSString *name;
@property double mmX,mmY,mmZ;

-(id) initWithName: (NSString *) inName
			   withX: (double) inX 
			   withY: (double) inY 
			   withZ: (double) inZ;
-(double) distanceFrom: (ROImm *) otherROI;
-(NSString *)description;
@end
