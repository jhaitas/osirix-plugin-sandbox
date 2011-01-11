//
//  StereotaxPointFilter.h
//  StereotaxPoint
//
//  Copyright (c) 2011 John Haitas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import "StereotaxPointController.h"

@interface StereotaxPointFilter : PluginFilter {
    StereotaxPointController *stereotaxPointController;
}

- (long) filterImage:(NSString*) menuName;

- (ViewerController *) getViewerController;

@end
