//
//  ConsoleSuccessFilter.h
//  ConsoleSuccess
//
//  Copyright (c) 2010 John Haitas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface ConsoleSuccessFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end
