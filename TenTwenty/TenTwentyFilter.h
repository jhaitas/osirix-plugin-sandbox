//
//  TenTwentyFilter.h
//  TenTwenty
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@class TenTwentyController;

@interface TenTwentyFilter : PluginFilter {
    TenTwentyController *tenTwenty;
}

- (long) filterImage:(NSString*) menuName;

- (ViewerController *) getViewerController;

@end
