//
//  ViewTemplateFilter.h
//  ViewTemplate
//
//  Copyright (c) 2010 John. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import "StereotaxCoord.h"
#import "tenTwentyTemplate.h"

@interface ViewTemplateFilter : PluginFilter {
	BOOL				foundNasion,foundInion;
	StereotaxCoord		*nasion;
	StereotaxCoord		*inion;
	tenTwentyTemplate	*myTenTwenty;
}

- (long) filterImage:(NSString*) menuName;
- (void) findUserInput;
- (void) getROI: (ROI *) thisROI fromPix: (DCMPix *) thisPix toCoords:(double *) location;
- (void) addElectrodes;

@end
