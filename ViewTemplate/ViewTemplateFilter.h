//
//  ViewTemplateFilter.h
//  ViewTemplate
//
//  Copyright (c) 2010 John. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import "ROImm.h"
#import "tenTwentyTemplate.h"

@interface ViewTemplateFilter : PluginFilter {
	int					originROIslice;
	ROImm				*originROI;
	tenTwentyTemplate	*myTenTwenty;
}

- (long) filterImage:(NSString*) menuName;
- (void) findOriginROI;
- (void) addElectrodes;

@end
