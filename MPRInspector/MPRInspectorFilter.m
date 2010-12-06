//
//  MPRInspectorFilter.m
//  MPRInspector
//
//  Copyright (c) 2010 John. All rights reserved.
//

#import "MPRInspectorFilter.h"

@implementation MPRInspectorFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
    mprInspector = [[MPRInspectorController alloc] initWithOwner:(id *)self]; 
    
    return 0;
}

- (ViewerController *) viewerController
{
    return viewerController;
}

@end
