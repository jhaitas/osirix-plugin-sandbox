//
//  ROImm.h
//  DistanceROI
//
//  Created by John Haitas on 6/9/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// ROImm is a lightweight class for storing the name...
// ... and coordinates (mm) of an ROI
@interface ROImm : NSObject {
	NSString * name;
	double mmX,mmY,mmZ;
}
@property(assign) NSString *name;
@property double mmX,mmY,mmZ;

// Initializes an instance of this class
-(id) initWithName: (NSString *) inName
			   withX: (double) inX 
			   withY: (double) inY 
			   withZ: (double) inZ;

// Returns the distance from the other referenced ROI
-(double) distanceFrom: (ROImm *) otherROI;

-(void) dicomCoords: (double *)theDICOMcoords;

// Returns a string describing an instance
-(NSString *)description;

-(void) dealloc;
@end
