//
//  TenTwentyFilter.h
//  TenTwenty
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import "TenTwentyController.h"

@interface TenTwentyFilter : PluginFilter {
    TenTwentyController     *tenTwenty;
}

- (long) filterImage:(NSString*) menuName;

@end
