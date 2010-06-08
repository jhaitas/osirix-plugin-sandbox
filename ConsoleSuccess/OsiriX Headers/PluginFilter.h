/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import <Cocoa/Cocoa.h>

#import "DCMPix.h"				// An object containing an image, including pixels values
#import "ViewerController.h"	// An object representing a 2D Viewer window
#import "DCMView.h"				// An object representing the 2D pane, contained in a 2D Viewer window
#import "MyPoint.h"				// An object representing a point
#import "ROI.h"					// An object representing a ROI


/** \brief Base class for plugins */
@interface PluginFilter : NSObject
{
	ViewerController*   viewerController;   // Current (frontmost and active) 2D viewer containing an image serie
}

+ (PluginFilter *)filter;

// FUNCTIONS TO SUBCLASS

/** This function is called to apply your plugin */
- (long) filterImage: (NSString*) menuName;

/** This function is the entry point of Pre-Process plugins */
- (long) processFiles: (NSMutableArray*) files;

/** This function is the entry point of Report plugins 
* action = @"dateReport"	-> return NSDate date of creation or modification of the report, nil if no report available
* action = @"deleteReport"	-> return nil, delete the report
* action = @"openReport"   -> return nil, open and display the report, create a new one if no report available 
*/
- (id) report: (NSManagedObject*) study action:(NSString*) action;



/** This function is called at the OsiriX startup, if you need to do some memory allocation, etc. */
- (void) initPlugin;

/** Opportunity for plugins to make Menu changes if necessary */

- (void)setMenus;

// UTILITY FUNCTIONS - Defined in the PluginFilter.m file

/** Return the complete lists of opened studies in OsiriX */
/** NSArray contains an array of ViewerController objects */
- (NSArray*) viewerControllersList;

/** Create a new 2D window, containing a copy of the current series */
- (ViewerController*) duplicateCurrent2DViewerWindow;

// Following stubs are to be subclassed by report filters.  Included here to remove compile-time warning messages.
/** Stub is to be subclassed by report filters */
- (id)reportDateForStudy: (NSManagedObject*)study;
/** Stub is to be subclassed by report filters */
- (void)deleteReportForStudy: (NSManagedObject*)study;
/** Stub is to be subclassed by report filters */
- (void)createReportForStudy: (NSManagedObject*)study;

/** PRIVATE FUNCTIONS - DON'T SUBCLASS OR MODIFY */
- (long) prepareFilter:(ViewerController*) vC;
@end
