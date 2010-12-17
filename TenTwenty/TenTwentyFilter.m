//
//  TenTwentyFilter.m
//  TenTwenty
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "TenTwentyFilter.h"
#import "TenTwentyController.h"

@implementation TenTwentyFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
    tenTwenty = [[TenTwentyController alloc] init];
    
    [tenTwenty prepareTenTwenty:self];

    return 0;
}

- (ViewerController *) getViewerController
{
    return viewerController;
}

@end
