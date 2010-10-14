//
//  StereotaxCoord.h
//  ViewTemplate
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StereotaxCoord : NSObject {
	NSString	*name;
	float		AP,ML,DV;
}

@property (assign)  NSString *name;
@property           float AP,ML,DV;


// Initializes an instance of this class
- (id) initWithName: (NSString *)   inName
			 withAP: (float)        inAP 
			 withML: (float)        inML
			 withDV: (float)        inDV;

- (id) initWithName: (NSString *) inName
    withDicomCoords: (float *) dicomCoords;

- (StereotaxCoord *) copy;


// for remapping orientation of stereotaxic coordinates
- (void) remapWithOrientation: (NSMutableDictionary *) theOrientation;

// returns coordinates mapped back to DICOM
- (void) returnDICOMCoords: (float *) dicomCoords
		   withOrientation: (NSMutableDictionary *) theOrientation;

// Returns a string describing an instance
- (NSString *) description;

@end
