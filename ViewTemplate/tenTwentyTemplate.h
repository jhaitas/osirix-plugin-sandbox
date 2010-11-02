//
//  tenTwentyTemplate.h
//  ViewTemplate
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StereotaxCoord.h"
#import "parseCSV.h"


@interface tenTwentyTemplate : NSObject {
    StereotaxCoord          *userNasion,*userInion;
    double                  templateM1M2_AP;
    NSMutableDictionary     *orientation,*direction;
    
    // electrodes is an array of StereotaxCoord objects
    NSMutableArray    *electrodes;
}
@property (assign)    StereotaxCoord        *userNasion;
@property (assign)    StereotaxCoord        *userInion;
@property (assign)    NSMutableDictionary   *orientation;
@property (assign)    NSMutableDictionary   *direction;
@property (assign)    NSMutableArray        *electrodes;


- (id) initWithNasion: (StereotaxCoord *) thisNasion
             andInion: (StereotaxCoord *) thisInion;

- (void) computeOrientation;
- (void) populateTemplate;
- (NSMutableDictionary *) generateElectrodeDict;
- (StereotaxCoord *) getElectrodeWithName: (NSString *) theName;
- (void) shiftCoordinates;
- (void) scaleCoordinatesAP;
- (void) scaleCoordinatesMLwithM1: (StereotaxCoord *) userM1
                            andM2: (StereotaxCoord *) userM2;
- (void) shiftElectrodesUp: (double) mmDistance;

@end
