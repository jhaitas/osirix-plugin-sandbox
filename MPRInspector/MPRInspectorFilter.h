//
//  MPRInspectorFilter.h
//  MPRInspector
//
//  Copyright (c) 2010 John. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import "MPRInspectorController.h"

@interface MPRInspectorFilter : PluginFilter {
    MPRInspectorController *mprInspector;
}

- (long) filterImage:(NSString*) menuName;
- (ViewerController *) viewerController;

@end
