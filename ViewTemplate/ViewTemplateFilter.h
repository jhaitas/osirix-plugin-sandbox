//
//  ViewTemplateFilter.h
//  ViewTemplate
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import "StereotaxCoord.h"
#import "tenTwentyTemplate.h"

@interface ViewTemplateFilter : PluginFilter {
	BOOL				foundNasion,foundInion;
	StereotaxCoord		*nasion,*inion;
	StereotaxCoord		*userM1,*userM2;
	tenTwentyTemplate	*myTenTwenty;
}

- (long) filterImage:(NSString*) menuName;
- (void) findUserInput;
- (void) getROI: (ROI *) thisROI 
		fromPix: (DCMPix *) thisPix 
	   toCoords:(double *) location;


- (void) getUserM1andM2;

- (void) addElectrodes;
- (void) lowerElectrode: (ROI *) thisROI 
				inSlice: (DCMPix *) thisSlice;

@end
