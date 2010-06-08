//
//  ConsoleSuccessFilter.m
//  ConsoleSuccess
//
//  Copyright (c) 2010 John. All rights reserved.
//

#import "ConsoleSuccessFilter.h"

@implementation ConsoleSuccessFilter

- (void) initPlugin
{
	NSLog(@"ConsoleSuccess plugin initialization.\n");
}

- (long) filterImage:(NSString*) menuName
{	
	// In this plugin, we will simply print 'ConsoleSuccess Success!' to Console
	NSLog(@"%@ Success!\n",menuName);
	
	return 0; // No Errors
}

@end
