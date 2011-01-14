//
//  StereotaxPointController.h
//  StereotaxPoint
//
//  Created by John Haitas on 1/6/11.
//  Copyright 2011 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"
#import "MPRHeaders.h"

#define MAG(v1) sqrt(v1[0]*v1[0]+v1[1]*v1[1]+v1[2]*v1[2]);

#define UNIT(dest,v1) \
dest[0]=v1[0]/MAG(v1); \
dest[1]=v1[1]/MAG(v1); \
dest[2]=v1[2]/MAG(v1);

@interface StereotaxPointController : NSObject {
    
    PluginFilter    *owner;
    
    ViewerController    *viewerController;
    MPRController       *mprViewer;
    VRController        *vrViewer;
    
    NSComboBox  *apViewSelect,*mlViewSelect,*dvViewSelect;
    NSTextField *originX,*originY,*originZ;
    NSTextField *apX,*apY,*apZ;
    NSTextField *mlX,*mlY,*mlZ;
    NSTextField *dvX,*dvY,*dvZ;
    NSColorWell *pointColor;
    NSTextField *pointAP,*pointML,*pointDV;
}

@property (assign) IBOutlet NSComboBox  *apViewSelect,*mlViewSelect,*dvViewSelect;
@property (assign) IBOutlet NSTextField *originX,*originY,*originZ;
@property (assign) IBOutlet NSTextField *apX,*apY,*apZ;
@property (assign) IBOutlet NSTextField *mlX,*mlY,*mlZ;
@property (assign) IBOutlet NSTextField *dvX,*dvY,*dvZ;
@property (assign) IBOutlet NSColorWell *pointColor;
@property (assign) IBOutlet NSTextField *pointAP,*pointML,*pointDV;

- (id) init;

- (void) prepareStereotaxPoint: (PluginFilter *) stereotaxPointFilter;

- (IBAction) open3dMpr: (id) sender;
- (IBAction) setOriginAndDirections: (id) sender;
- (IBAction) flipAPSigns: (id) sender;
- (IBAction) flipMLSigns: (id) sender;
- (IBAction) flipDVSigns: (id) sender;
- (IBAction) openVrViewer: (id) sender;
- (IBAction) importCSV: (id) sender;
- (IBAction) addPoint: (id) sender;

- (BOOL)readCsvFromURL:(NSURL *)absoluteURL;

- (void) setAxisComponents: (MPRDCMView *) view
                    xField: (NSTextField *) xField
                    yField: (NSTextField *) yField
                    zField: (NSTextField *) zField;

- (void) setPoint:(NSDictionary *) dict;
- (void) getVrViewer3dPointColor;

@end
