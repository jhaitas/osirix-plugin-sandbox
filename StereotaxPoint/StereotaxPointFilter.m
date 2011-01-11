//
//  StereotaxPointFilter.m
//  StereotaxPoint
//
//  Copyright (c) 2011 John Haitas. All rights reserved.
//

#import "StereotaxPointFilter.h"

@implementation StereotaxPointFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
    stereotaxPointController = [[StereotaxPointController alloc] init];
    
    [stereotaxPointController prepareStereotaxPoint:self];
    
    return 0;
}

- (ViewerController *) getViewerController
{
    return viewerController;
}

@end
