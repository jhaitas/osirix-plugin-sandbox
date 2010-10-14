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
    tenTwenty = [[TenTwentyController alloc] initWithOwner:(id *)self]; 

    // there should be an ROI named 'nasion' and 'inion'
    [tenTwenty findUserInput];
    
    // check if 'nasion' and 'inion' were found
    if (tenTwenty.foundNasion && tenTwenty.foundInion) {
        [tenTwenty computeOrientation];
        
        // remap coordinates per computed orientation
        [tenTwenty remapNasionAndInion];
    } else {
        // failed to locate 'nasion' and 'inion'
        [tenTwenty release];
        
        // notify the user through the NSRunAlertPanel        
        NSRunAlertPanel(NSLocalizedString(@"Plugin Error", nil),
                        NSLocalizedString(@"Unable to locate 'nasion' and 'inion'!", nil), 
                        nil, nil, nil);
        return -1;
    }
    return 0;
}

- (ViewerController *) getViewerController
{
    return viewerController;
}

@end
