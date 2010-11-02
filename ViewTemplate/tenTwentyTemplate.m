//
//  tenTwentyTemplate.m
//  ViewTemplate
//
//  Created by John Haitas.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "tenTwentyTemplate.h"


@implementation tenTwentyTemplate

@synthesize userNasion,userInion,orientation,direction;
@synthesize electrodes;

- (id) initWithNasion: (StereotaxCoord *) thisNasion
             andInion: (StereotaxCoord *) thisInion
{
    if (self = [super init])
    {        
        // allocate and init orientation and direction dictionaries
        orientation = [[NSMutableDictionary alloc] init];
        direction   = [[NSMutableDictionary alloc] init];
        
        // allocate and inititalize electrodes array
        electrodes = [[NSMutableArray alloc] init];
        
        userNasion  = [[StereotaxCoord alloc] initWithName:[NSString stringWithString:thisNasion.name]
                                                withAP:thisNasion.AP
                                                withML:thisNasion.ML
                                                withDV:thisNasion.DV    ];
        
        userInion   = [[StereotaxCoord alloc] initWithName:[NSString stringWithString:thisInion.name]
                                                withAP:thisInion.AP
                                                withML:thisInion.ML
                                                withDV:thisInion.DV    ];
        
        // compute orientation of AP, ML, and DV
        [self computeOrientation];
        
        // remap coordinates per computed orientation
        [userNasion remapWithOrientation:orientation];
        [userInion remapWithOrientation:orientation];
        
        // create array containing electrode names and coordinates
        [self populateTemplate];
        
        // shift template values to match DICOM coordinate space
        [self shiftCoordinates];
        
        // scale the template to the subject
        [self scaleCoordinatesAP];
    }
    
    return self;    
}

// coordinates natively in (x,y,z) ...
// ... greatest difference between userNasion and userInion should be AP
// ... ML should be same in userNasion and userInion
// ... DV should be smaller difference than AP
- (void) computeOrientation
{
    int             i,firstIndex,secondIndex;
    int             indexAP,indexML,indexDV;
    double          thisDouble,firstDouble,secondDouble;
    int             dir[3];
    NSNumber        *diffAP,*diffML,*diffDV;
    NSMutableArray  *diff;
    
    
    diffAP  = [[NSNumber alloc] initWithDouble:(userNasion.AP - userInion.AP)];
    diffML  = [[NSNumber alloc] initWithDouble:(userNasion.ML - userInion.ML)];
    diffDV  = [[NSNumber alloc] initWithDouble:(userNasion.DV - userInion.DV)];
    
    // set directions based on difference between userNasion and userInion ...
    // ... ML is assumed to be zero and will be given a direction of 1
    dir[0]  = ([diffAP doubleValue] >= 0 ? 1 : -1);
    dir[1]  = ([diffML doubleValue] >= 0 ? 1 : -1);
    dir[2]  = ([diffDV doubleValue] >= 0 ? 1 : -1);
    
    diff    = [[NSMutableArray alloc] initWithObjects:diffAP,diffML,diffDV,nil];
    
    
    // no longer need these objects...
    // ... they have been incorporated into diff array
    [diffAP release];
    [diffML release];
    [diffDV release];
    
    
    // initialize values that aren't acceptable after the following routine
    indexML = -1;
    
    // first we identify and eliminate ML ...
    // ... there should be only one plane with no difference
    for (i = 0; i < [diff count]; i++) {
        thisDouble = [[diff objectAtIndex:i] doubleValue];
        if (thisDouble == 0.0) {
            // found ML ... store its index
            indexML = i;
        }
    }
    
    // We failed to find the ML index
    if (indexML == -1) {
        [diff release];
        return;
    }
    
    // initialize values that won't be acceptable after the following routine
    firstIndex      = -1;
    secondIndex     = -1;
    firstDouble     = 0.0;
    secondDouble    = 0.0;
    
    // now find which magnitude is greater between remaining diffs
    // [diff count] should equal 3
    // we don't want the first for loop to hit the last diff element
    for (i = 0; i < ([diff count] - 1); i++) {
        // ignore item identified as ML
        if (i == indexML) continue;
        firstDouble = [[diff objectAtIndex:i] doubleValue];
        firstIndex = i;
    }
    
    // start with the index after previously selected first index
    for (i = firstIndex + 1; i < [diff count]; i++) {
        // ignore item identified as ML
        if (i == indexML) continue;
        secondDouble = [[diff objectAtIndex:i] doubleValue];
        secondIndex = i;
    }
    
    // release diff object because we no longer need it
    [diff release];
    
    // set appropriate indices based on magnitude comparison
    if (fabs(firstDouble) > fabs(secondDouble)) {
        indexAP = firstIndex;
        indexDV = secondIndex;
    } else {
        indexAP = secondIndex;
        indexDV = firstIndex;
    }
    
    DLog(@"dirAP ,dirML ,dirDV  = %d,%d,%d\n",dir[indexAP],dir[indexML],dir[indexDV]);
    
    // set orientation dictionary objects
    [orientation setObject:[NSNumber numberWithInt:indexAP] forKey:@"AP"];
    [orientation setObject:[NSNumber numberWithInt:indexML] forKey:@"ML"];
    [orientation setObject:[NSNumber numberWithInt:indexDV] forKey:@"DV"];
    
    // set direction dictionary objects
    [direction setObject:[NSNumber numberWithInt:dir[indexAP]] forKey:@"AP"];
    [direction setObject:[NSNumber numberWithInt:dir[indexML]] forKey:@"ML"];
    [direction setObject:[NSNumber numberWithInt:dir[indexDV]] forKey:@"DV"];
}

- (void) populateTemplate
{
    // Identify plugin Bundle
    NSString *path            = [[[NSBundle bundleWithIdentifier:@"edu.vanderbilt.viewtemplate"] resourcePath] retain];
    NSString *fullFilename    = [[NSString stringWithFormat:@"%@/zeroedTemplate.csv",path] retain];

    // parse the csv file included in plugin bundle ...
    // each parsed line goes into parsedElectrodes array
    CSVParser        *myCSVParser        = [[CSVParser alloc] init];
    NSMutableArray    *parsedElectrodes;
    [myCSVParser setDelimiter:','];
    if ([myCSVParser openFile:fullFilename]) {
        DLog(@"Success opening %@\n",fullFilename);
        parsedElectrodes = [[myCSVParser parseFile] retain];
        DLog(@"%d csv lines parsed.\n",[parsedElectrodes count]);
    } else {
        DLog(@"Failed to open %@\n",fullFilename);
        [myCSVParser release];
        [fullFilename release];
        [path release];
        return;
    }
    // close csv file
    [myCSVParser closeFile];
    
    // release objects used by the csv parser
    [myCSVParser release];
    [fullFilename release];
    [path release];
    
    // remove first two objects from array (header line and origin)
    [parsedElectrodes removeObjectsInRange:NSMakeRange(0, 2)];
    
    // convert each parsed line to a StereotaxCoord
    for (id thisParsedLine in parsedElectrodes) {
        NSString *thisName;
        float thisAP,thisML,thisDV;
        
        thisName = [NSString stringWithString:[thisParsedLine objectAtIndex:0]];
        // adjust values according to DICOM directions
        thisAP = [[thisParsedLine objectAtIndex:1] doubleValue] * [[direction objectForKey:@"AP"] intValue];
        thisML = [[thisParsedLine objectAtIndex:2] doubleValue] * [[direction objectForKey:@"ML"] intValue];
        thisDV = [[thisParsedLine objectAtIndex:3] doubleValue] * [[direction objectForKey:@"DV"] intValue];

        StereotaxCoord *tmpElectrode = [[StereotaxCoord alloc] initWithName:thisName
                                                                     withAP:thisAP
                                                                     withML:thisML
                                                                     withDV:thisDV        ];
        [electrodes addObject: tmpElectrode];
        [tmpElectrode release];
    }
    
    // release parsed electrodes array
    [parsedElectrodes release];
}

- (NSMutableDictionary *) generateElectrodeDict
{
    NSMutableDictionary    *tmpElectrodeDict;
    
    // populate a temporary dictionary
    tmpElectrodeDict = [NSMutableDictionary dictionary];
    for (StereotaxCoord *thisElectrode in electrodes) {
        [tmpElectrodeDict setObject:thisElectrode 
                             forKey:[NSString stringWithString:thisElectrode.name]];
    }
    return tmpElectrodeDict;
}


- (StereotaxCoord *) getElectrodeWithName: (NSString *) theName
{
    StereotaxCoord *theElectrode;    
    theElectrode = [[[self generateElectrodeDict] objectForKey:theName] copy];
    
    return [theElectrode autorelease];
}

- (void) shiftCoordinates
{
    float    diffAP,diffML,diffDV;
    
    // for now we are matching userNasion to templateNasion electrode
    StereotaxCoord    *firstElectrode = [[electrodes objectAtIndex:0] copy];
    
    // calcuate difference from nasion to Fpz
    diffAP = userNasion.AP - firstElectrode.AP;
    diffML = userNasion.ML - firstElectrode.ML;
    diffDV = userNasion.DV - firstElectrode.DV;
    
    // release firstElectrode because it is no longer needed
    [firstElectrode release];
    
    // apply differences to each electrode
    for (StereotaxCoord *thisElectrode in electrodes) {
        thisElectrode.AP += diffAP;
        thisElectrode.ML += diffML;
        thisElectrode.DV += diffDV;
    }
}

- (void) scaleCoordinatesAP
{
    float            referenceAP,scaleAP;
    StereotaxCoord    *templateNasion,*templateInion;
    
    // locate Fpz and Oz which are used to scale on AP plane
    templateNasion  = [self getElectrodeWithName:@"nasion"];
    templateInion   = [self getElectrodeWithName:@"inion"];
    
    // compute the scale using absolute values in differences
    scaleAP = (fabs(userNasion.AP - userInion.AP) / fabs(templateNasion.AP - templateInion.AP));
    
    // set reference AP coordinate
    referenceAP = templateNasion.AP;
    
    // apply scale to each electrode in template
    for (StereotaxCoord *thisElectrode in electrodes) {
        thisElectrode.AP = referenceAP - (scaleAP * (referenceAP - thisElectrode.AP));
        if ([thisElectrode.name isEqualToString:@"M1"] || [thisElectrode.name isEqualToString:@"M2"]) {
            DLog(@"%@ AP = %f mm\n",thisElectrode.name,thisElectrode.AP);
            templateM1M2_AP = thisElectrode.AP;
        }
    }
}

- (void) scaleCoordinatesMLwithM1: (StereotaxCoord *) userM1
                            andM2: (StereotaxCoord *) userM2
{
    float           referenceML,scaleML;
    StereotaxCoord  *M1,*M2,*Fpz;
    
    float           scaleM1,scaleM2;
    
    // locate M1 and M2 which are used to scale on ML planes
    M1    = [self getElectrodeWithName:@"M1"];
    M2    = [self getElectrodeWithName:@"M2"];
    
    // locate Fpz which is used to reference all electrodes
    Fpz = [self getElectrodeWithName:@"Fpz"];
    
    // the following three lines are to examine the difference in scale between sides    
    scaleM1 = (fabs(Fpz.ML - userM1.ML) / fabs(Fpz.ML - M1.ML));
    scaleM2 = (fabs(Fpz.ML - userM2.ML) / fabs(Fpz.ML - M2.ML));
    DLog(@"scaleM1 : scaleM2 = %f : %f\n",scaleM1,scaleM2);
    
    // compute the scale using absolute values in differences
    scaleML = (fabs(userM1.ML - userM2.ML) / fabs(M1.ML - M2.ML));
    
    // set reference ML coordinate
    referenceML = Fpz.ML;
    
    DLog(@"scaleML = %f\n",scaleML);
    DLog(@"referenceML = %f\n",referenceML);
    
    // apply scale to each electrode in template
    for (StereotaxCoord *thisElectrode in electrodes) {
        DLog(@"%@\n",thisElectrode);
        thisElectrode.ML = referenceML - (scaleML * (referenceML - thisElectrode.ML));
        DLog(@"%@\n",thisElectrode);
    }
}

- (void) shiftElectrodesUp: (double) mmDistance
{
    for (StereotaxCoord *thisElectrode in electrodes) {
        thisElectrode.DV += (mmDistance * [[direction objectForKey:@"DV"] intValue]);
    }
}

@end
