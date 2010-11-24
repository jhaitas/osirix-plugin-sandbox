//
//  ViewTemplateFilter.m
//  ViewTemplate
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "ViewTemplateFilter.h"

@implementation ViewTemplateFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
    DLog(@"Starting Plugin\n");
    
    
    if ([NSBundle loadNibNamed:@"tenTwentyTemplateHUD" owner:self]) {
        DLog(@"successfully loaded xib");
    } else {
        DLog(@"failed to load xib");
    }
    
    // these values should be made user configurable in the future
    minScalpValue = 45.0;
    maxSkullValue = 45.0;
    
    // there should be an ROI named 'nasion' and 'inion'
    [self findUserInput];
    
    // check if 'nasion' and 'inion' were found
    if (foundNasion && foundInion) {
        // pass the nasion and inion to the tenTwentyTemplate
        myTenTwenty = [[tenTwentyTemplate alloc] initWithNasion:nasion
                                                       andInion:inion                ];
        
        
        
        // set default values for the fields in the HUD
        [minScalpField setFloatValue:minScalpValue];
        [maxSkullField setFloatValue:maxSkullValue];
        
        
        // tenTwentyTemplate has been allocated and populated ...
        // ... it has been scaled on the AP plane ...
        // ... M1 and M2 should tell us where to slice on ML plane
        // ... we need user to input M1 and M2 ...
        // ... we will the scale coordinates
        [self getUserM1andM2];
    } else {
        // notify the user through the NSRunAlertPanel        
        NSRunAlertPanel(NSLocalizedString(@"Plugin Error", nil),
                        NSLocalizedString(@"Unable to locate 'nasion' and 'inion'!", nil), 
                        nil, nil, nil);
    }

    
    DLog(@"executed method\n");
    return 0;
}

- (IBAction) dropElectrodes: (id) sender
{    
    // set variables according to user input in text fields
    minScalpValue = [minScalpField floatValue];
    maxSkullValue = [maxSkullField floatValue];
    
    
    // move electrodes 20 mm above skull
    [myTenTwenty shiftElectrodesUp: 20.0];
    
    // now we are ready to add the electrodes to the DICOM
    // this call might belong somewhere else ...
    // ... possibly in in tenTwentyTemplate
    [self addElectrodes];
}

- (void) findUserInput
{
    int     i,ii;
    float   location[3];
    ROI     *selectedROI;    
    
    NSArray *pixList;
    NSArray *roiList;
    NSArray *thisRoiList;
    DCMPix  *thisPix;
    
    pixList = [viewerController pixList];
    roiList = [viewerController roiList];
    
    // step through each ROI list
    for (i = 0; i < [roiList count]; i++) {
        thisRoiList = [roiList objectAtIndex:i];
        thisPix = [pixList objectAtIndex:i];
        // step through each ROI in the current ROI list
        for (ii = 0; ii < [thisRoiList count]; ii++) {
            selectedROI = [thisRoiList objectAtIndex:ii];
            // check if this ROI is named 'nasion'
            if ([selectedROI.name isEqualToString:@"nasion"]) {
                [self getROI:selectedROI fromPix:thisPix toCoords:location];
                nasion = [[StereotaxCoord alloc] initWithName:selectedROI.name
                                              withDicomCoords:location          ];
                foundNasion = TRUE;
            }
            // check if this ROI is named 'inion'
            if ([selectedROI.name isEqualToString:@"inion"]) {
                [self getROI:selectedROI fromPix:thisPix toCoords:location];
                inion = [[StereotaxCoord alloc] initWithName:selectedROI.name
                                             withDicomCoords:location          ];
                foundInion = TRUE;
            }
        }
    }
}


- (void) getROI: (ROI *) thisROI fromPix: (DCMPix *) thisPix toCoords:(float *) location
{                
    NSMutableArray *roiPoints = [ thisROI points ];
    NSPoint roiCenterPoint;
    
    // calc center of the ROI
    if ( [ thisROI type ] == t2DPoint ) {
        // ROI has a bug which causes miss-calculating center of 2DPoint roi
        roiCenterPoint = [ [ roiPoints objectAtIndex: 0 ] point ];
    } else {
        roiCenterPoint = [ thisROI centroid ];
    }
    
    // convert pixel values to mm values
    [thisPix convertPixX:roiCenterPoint.x
                    pixY:roiCenterPoint.y
                 toDICOMCoords:location     ];
    DLog(@"%@ coordinates (AP,ML,DV) = (%.3f,%.3f,%.3f)\n",thisROI.name,location[0],location[1],location[2]);
}



- (void) getUserM1andM2
{
    
    int             indexML,bestSlice;
    float           dicomCoords[3],sliceCoords[3];
    StereotaxCoord  *M1;
    
    // In this plugin, we will simply duplicate the current 2D window!
    
    // Create new viewer in ML plane for selecting M1 and M2
    viewerML = [self duplicateCurrent2DViewerWindow];
    
    // get the appropriate index for an ML value
    indexML = [[myTenTwenty.orientation objectForKey:@"ML"] intValue];
    
    // get M1 electrode to locate best slice
    M1 = [myTenTwenty getElectrodeWithName:@"M1"];
    
    // get DICOM coordinates for M1 electrode
    [M1 returnDICOMCoords:dicomCoords withOrientation:myTenTwenty.orientation];
    
    // reslice DICOM on ML plane
    [viewerML processReslice: indexML :FALSE];
    
    // get best slice to see M1    
    bestSlice = [DCMPix nearestSliceInPixelList:[[viewerML imageView] dcmPixList]
                                withDICOMCoords:dicomCoords
                                    sliceCoords:sliceCoords                                    ];
    
    // View slice for placing M1 and M2
    [[viewerML imageView] setIndex: bestSlice];
    
    // update screen
    [viewerML updateImage:self];
    
    // make the new viewer key window and bring it to the front
    [[viewerML window] makeKeyAndOrderFront:self];
    
    // give the user 2D point tool
    [[viewerML imageView] setCurrentTool:t2DPoint];
    
    // start a timer to wait for user to place 2 ROIs
    [NSTimer scheduledTimerWithTimeInterval:2
                                     target:self
                                   selector:@selector(watchViewerML:)
                                   userInfo:nil
                                    repeats:YES];    
}

- (void) watchViewerML: (NSTimer *) theTimer
{
    float  location[3];
    DCMPix  *thisPix;
    ROI     *selectedROI;
    
    thisPix = [[viewerML imageView] curDCM];
    
    if ([[[viewerML imageView] curRoiList] count] >= 2) {
        // we have located 2 ROIs
        [theTimer invalidate];
        
        // get the first ROI and store it in StereotaxCoord object
        selectedROI = [[[viewerML imageView] curRoiList] objectAtIndex:0];
        [self getROI:selectedROI fromPix:thisPix toCoords:location];
        userM1 = [[StereotaxCoord alloc] initWithName:selectedROI.name
                                      withDicomCoords:location          ];
        
        // get the second ROI and store it in StereotaxCoord object
        selectedROI = [[[viewerML imageView] curRoiList] objectAtIndex:1];
        [self getROI:selectedROI fromPix:thisPix toCoords:location];
        userM2 = [[StereotaxCoord alloc] initWithName:selectedROI.name
                                      withDicomCoords:location          ];
        
        // remap coordinates according to previously calculated orientation        
        [userM1 remapWithOrientation:myTenTwenty.orientation];
        [userM2 remapWithOrientation:myTenTwenty.orientation];
        
        // close the ML slice window
        [[viewerML window] performClose:self];
        
        // scale the coordinates on ML plane according to user inputs
        [myTenTwenty scaleCoordinatesMLwithM1: userM1 andM2: userM2];
        
        [dropElectrodes setEnabled:YES];
    }
}

- (void) addElectrodes
{
    int     thisRoiType,bestSlice;
    double  pixelSpacingX,pixelSpacingY;
    float   dicomCoords[3],sliceCoords[3];
    
    // temporary pointers for creating new ROI
    ROI     *thisROI;
    
    // pointer to current DCMPix in OsiriX
    DCMPix  *thisDCMPix    = [[viewerController imageView] curDCM];
    
    // parameters necessary for initializting a new ROI
    thisRoiType     = t2DPoint;
    pixelSpacingX   = [thisDCMPix pixelSpacingX];
    pixelSpacingY   = [thisDCMPix pixelSpacingY];
        
    for (StereotaxCoord *thisElectrode in myTenTwenty.electrodes) {
        // do not place nasion or inion from template ...
        // do not place M1 or M2 either
        if ([thisElectrode.name isEqualToString:@"nasion"]) continue;
        if ([thisElectrode.name isEqualToString:@"inion"]) continue;
        if ([thisElectrode.name isEqualToString:@"M1"]) continue;
        if ([thisElectrode.name isEqualToString:@"M2"]) continue;
        
        // get DICOM coords which we will convert to slice coords
        [thisElectrode returnDICOMCoords:dicomCoords withOrientation:myTenTwenty.orientation];
        
        // find nearest slice
        bestSlice = [DCMPix nearestSliceInPixelList:[[viewerController imageView] dcmPixList]
                                    withDICOMCoords:dicomCoords
                                        sliceCoords:sliceCoords                                    ];
        
        // allocate and initialize a new ROI
        thisROI = [[ROI alloc] initWithType:thisRoiType
                                           :pixelSpacingX
                                           :pixelSpacingY
                                           :NSMakePoint(0.0, 0.0)];
        
        // move the ROI to the correct location
        thisROI.rect = NSOffsetRect(thisROI.rect, sliceCoords[0]/pixelSpacingX, sliceCoords[1]/pixelSpacingY);
        
        // give the ROI the correct name
        thisROI.name = [NSString stringWithString:thisElectrode.name];
                
        // add the new ROI to the correct ROI list
        [[[[viewerController imageView] dcmRoiList] objectAtIndex:bestSlice] addObject:thisROI];
        
        // lower the electrode to the surface of the skull
        [self lowerElectrode:thisROI inSlice:[[[viewerController imageView] dcmPixList] objectAtIndex:bestSlice]];
        
        [thisROI release];
    }
    // we are done with the user input nasion and inion ... remove them
    thisROI = [self findRoiWithName:@"nasion"];
    [[[viewerController imageView] curRoiList] removeObjectIdenticalTo:thisROI];
    thisROI = [self findRoiWithName:@"inion"];
    [[[viewerController imageView] curRoiList] removeObjectIdenticalTo:thisROI];
    
    // update screen
    [viewerController updateImage:self];
}

- (void) lowerElectrode: (ROI *) thisROI inSlice: (DCMPix *) thisSlice
{
    int     indexDV,directionDV;
    float   thisMin,thisMean,thisMax;
    double  pixelSpacingX,pixelSpacingY;
    float   dicomCoords[3],sliceCoords[3];
    BOOL    foundScalp,foundSkull;
    NSPoint roiPosition;
    NSPoint offsetShift;
    
    // initialize values
    indexDV         = [[myTenTwenty.orientation objectForKey:@"DV"] intValue];
    directionDV     = [[myTenTwenty.direction objectForKey:@"DV"] intValue];
    foundScalp      = NO;
    foundSkull      = NO;
    thisMin         = -1.0;
    thisMean        = -1.0;
    thisMax         = -1.0;
    pixelSpacingX   = [thisSlice pixelSpacingX];
    pixelSpacingY   = [thisSlice pixelSpacingY];
    
    // select this ROI (prerequisite for [ROI roiMove: :] method)
    [thisROI setROIMode: ROI_selected];
    
    if (indexDV == 2) {
        DLog(@"DV index indicates DV goes across slices... no implementation for this yet\n");
        return;
    }

    // drop till we locate the scalp
    while (!foundScalp) {
        roiPosition = thisROI.rect.origin;
        
        // get DICOM coordinates (in mm)
        [thisSlice convertPixX:roiPosition.x pixY:roiPosition.y toDICOMCoords:dicomCoords];
        
        // drop point .1 mm on DV plane
        dicomCoords[indexDV] -= (directionDV * .1);
        
        // convert back to slice coords
        [thisSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
        
        // determine how coordinates should be shifted
        offsetShift.x = (sliceCoords[0] / pixelSpacingX) - roiPosition.x;
        offsetShift.y = (sliceCoords[1] / pixelSpacingY) - roiPosition.y;
        
        // shift the ROI
        [thisROI roiMove:offsetShift :TRUE];
         
        // determine current pixel mean
        [thisSlice computeROI:thisROI :&thisMean :NULL :NULL :&thisMin :&thisMax];
        
        // detect if we have found the scalp
        if (thisMax > minScalpValue) {
            foundScalp = YES;
        }
        
        // be sure we haven't fallen to the bottom of the slice
        if (!(thisROI.rect.origin.x >= 0) || !(thisROI.rect.origin.y >= 0)) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
    
    // drop till we locate the skull
    while (!foundSkull) {
        roiPosition = thisROI.rect.origin;
        
        // get DICOM coordinates (in mm)
        [thisSlice convertPixX:roiPosition.x pixY:roiPosition.y toDICOMCoords:dicomCoords];
        
        // drop point .01 mm on DV plane
        dicomCoords[indexDV] -= (directionDV * .01);
        
        // convert back to slice coords
        [thisSlice convertDICOMCoords:dicomCoords toSliceCoords:sliceCoords];
        
        // determine how coordinates should be shifted
        offsetShift.x = (sliceCoords[0] / pixelSpacingX) - roiPosition.x;
        offsetShift.y = (sliceCoords[1] / pixelSpacingY) - roiPosition.y;
        
        // shift the ROI
        [thisROI roiMove:offsetShift :TRUE];
         
        // determine current pixel mean
        [thisSlice computeROI:thisROI :&thisMean :NULL :NULL :&thisMin :&thisMax];
        
        // detect if we have found the skull
        if (thisMin < maxSkullValue) {
            foundSkull = YES;
        }
        
        // be sure we haven't fallen to the bottom of the slice
        if (!(thisROI.rect.origin.x >= 0) || !(thisROI.rect.origin.y >= 0)) {
            DLog(@"%@ falling off slice!!!\n",thisROI.name);
            break;
        }
    }
    
    // put this ROI back to sleep
    [thisROI setROIMode: ROI_sleep];

}



- (ROI *) findRoiWithName: (NSString *) thisName
       inViewerController: (ViewerController *)vc
{
    NSArray *thisRoiList;
    ROI     *thisROI;
    
    for (thisRoiList in [[vc imageView] dcmRoiList]) {
        for (thisROI in thisRoiList) {
            if ([thisROI.name isEqualToString:thisName]) {
                return thisROI;
            }
        }
    }
    
    // if we don't find the ROI return nil
    return nil;
}

- (ROI *) findRoiWithName: (NSString *) thisName
{
    return [self findRoiWithName:thisName inViewerController:viewerController];
}

@end
