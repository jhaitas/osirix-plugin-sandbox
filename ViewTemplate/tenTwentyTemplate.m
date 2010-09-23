//
//  tenTwentyTemplate.m
//  ViewTemplate
//
//  Created by John Haitas on 9/16/10.
//  Copyright 2010 Vanderbilt University. All rights reserved.
//

#import "tenTwentyTemplate.h"


@implementation tenTwentyTemplate

@synthesize nasion,inion,orientation;
@synthesize electrodes;

- (id) initWithNasion: (StereotaxCoord *) thisNasion
			 andInion: (StereotaxCoord *) thisInion
{
	self = [super init];
	
	// allocate and init orientation dictionary
	orientation	= [[NSMutableDictionary alloc] init];
	
	// allocate and inititalize electrodes array
	electrodes = [[NSMutableArray alloc] init];
	
	nasion	= [[StereotaxCoord alloc] initWithName:[NSString stringWithString:thisNasion.name]
												withAP:thisNasion.AP
												withML:thisNasion.ML
												withDV:thisNasion.DV	];
	
	inion	= [[StereotaxCoord alloc] initWithName:[NSString stringWithString:thisInion.name]
												withAP:thisInion.AP
												withML:thisInion.ML
												withDV:thisInion.DV	];
	
	// compute orientation of AP, ML, and DV
	[self computeOrientation];
	
	// remap coordinates per computed orientation
	[nasion remapWithOrientation:orientation];
	[inion remapWithOrientation:orientation];
	
	// create array containing electrode names and coordinates
	[self populateTemplate];
	
	// shift template values to match DICOM coordinate space
	[self shiftCoordinates];
	
	// compute scaling factor
//	[self computeScalingFactor];
	
	// scale the template to the subject
//	[self scaleCoordinates];
	
	return self;	
}

// coordinates natively in (x,y,z) ...
// ... greatest difference between nasion and inion should be AP
// ... ML should be same in nasion and inion
// ... DV should be smaller difference than AP
//
// no doubt there is a more elegant way to do this
- (void) computeOrientation
{
	int					i,ii,firstIndex,secondIndex;
	double				thisDouble,firstDouble,secondDouble;
	int					indexAP,indexML,indexDV;
	NSNumber			*diffAP,*diffML,*diffDV;
	NSMutableArray		*diff;
	
	diffAP	= [NSNumber numberWithDouble:(nasion.AP - inion.AP)];
	diffML	= [NSNumber numberWithDouble:(nasion.ML - inion.ML)];
	diffDV	= [NSNumber numberWithDouble:(nasion.DV - inion.DV)];
	
	diff		= [[NSMutableArray alloc] initWithObjects:diffAP,diffML,diffDV,nil];
	
	// first we identify and eliminate ML
	for (i = 0; i < [diff count]; i++) {
		thisDouble = [[diff objectAtIndex:i] doubleValue];
		if (thisDouble == 0.0) {
			// found ML ... store its index
			indexML = i;
		}
	}
	
	// now find which magnitude is greater between remaining diffs
	for (i = 0; i < ([diff count] - 1); i++) {
		// ignore item identified as ML
		if (i == indexML) continue;
		firstDouble = [[diff objectAtIndex:i] doubleValue];
		firstIndex = i;
		for (ii = i + 1; ii < [diff count]; ii++) {
			// ignore item identified as ML
			if (ii == indexML) continue;
			secondDouble = [[diff objectAtIndex:ii] doubleValue];
			secondIndex = ii;
		}
	}
	
	if (fabs(firstDouble) > fabs(secondDouble)) {
		indexAP = firstIndex;
		indexDV = secondIndex;
	} else {
		indexAP = secondIndex;
		indexDV = firstIndex;
	}
	
	[orientation setObject:[NSNumber numberWithInt:indexAP] forKey:@"AP"];
	[orientation setObject:[NSNumber numberWithInt:indexML] forKey:@"ML"];
	[orientation setObject:[NSNumber numberWithInt:indexDV] forKey:@"DV"];
	
	NSLog(@"ML identified at index %d\n",indexML);
	
	NSLog(@"diffAP = %f\n",[diffAP doubleValue]);
	NSLog(@"diffML = %f\n",[diffML doubleValue]);
	NSLog(@"diffDV = %f\n",[diffDV doubleValue]);
	
	NSLog(@"(AP,ML,DV) are mapped as (%d,%d,%d)\n",indexAP,indexML,indexDV);
	
	NSLog(@"orientation is %@\n",orientation);
}

- (void) populateTemplate
{
	// Identify plugin Bundle
	NSString *name			= [NSString stringWithString:@"zeroedTemplate"];
	NSString *ext			= [NSString stringWithString:@"csv"];
	NSString *path			= [[NSBundle bundleWithIdentifier:@"edu.vanderbilt.viewtemplate"] resourcePath];
	NSString *fullFilename	= [NSString stringWithFormat:@"%@/%@.%@",path,name,ext];
		
	CSVParser		*myCSVParser		= [[CSVParser alloc] init];
	NSMutableArray	*parsedElectrodes;
	
	[myCSVParser setDelimiter:','];
	if ([myCSVParser openFile:fullFilename]) {
		NSLog(@"Success opening %@\n",fullFilename);
		parsedElectrodes = [myCSVParser parseFile];
		NSLog(@"%d csv lines parsed.\n",[parsedElectrodes count]);
	} else {
		NSLog(@"Failed to open %@\n",fullFilename);
		return;
	}

	// start from object at index 2 ...
	// ... index 0 contains headers ...
	// ... index 1 contains origin
	[parsedElectrodes removeObjectAtIndex:1];
	[parsedElectrodes removeObjectAtIndex:0];
	for (id thisParsedLine in parsedElectrodes) {
		StereotaxCoord *tmpElectrode = [StereotaxCoord alloc];
		[tmpElectrode initWithName:[[NSString alloc] initWithString:[thisParsedLine objectAtIndex:0]]
							 withAP:[[thisParsedLine objectAtIndex:1] doubleValue]
							 withML:[[thisParsedLine objectAtIndex:2] doubleValue]
							 withDV:[[thisParsedLine objectAtIndex:3] doubleValue]						];
		[electrodes addObject:tmpElectrode];
	}
	
	[myCSVParser closeFile];
	[myCSVParser release];
}

- (void) shiftCoordinates
{
	float	diffAP,diffML,diffDV;
	StereotaxCoord *thisElectrode;
	
	// for now we are matching nasion to Fpz electrode
	StereotaxCoord	*firstElectrode = [[electrodes objectAtIndex:0] copy];
	
	diffAP = nasion.AP - firstElectrode.AP;
	diffML = nasion.ML - firstElectrode.ML;
	diffDV = nasion.DV - firstElectrode.DV;
	
	NSLog(@"%@\n",firstElectrode);
	NSLog(@"%@\n",nasion);
	NSLog(@"(%.3f,%.3f,%.3f)\n",diffAP,diffML,diffDV);
	
	for (thisElectrode in electrodes) {
		thisElectrode.AP += diffAP;
		thisElectrode.ML += diffML;
		thisElectrode.DV += diffDV;
	}
}

- (void) computeScalingFactor
{
	float	scaleAP;
	StereotaxCoord	*Fpz,*Oz;
	
	// populate a temporary dictionary
	NSMutableDictionary	*tmpElectrodeDict = [[NSMutableDictionary alloc] init];;
	for (StereotaxCoord *thisElectrode in electrodes) {
		[tmpElectrodeDict setObject:thisElectrode forKey:[NSString stringWithString:thisElectrode.name]];
	}
	
	Fpz	= [[tmpElectrodeDict objectForKey:@"Fpz"] copy];
	Oz	= [[tmpElectrodeDict objectForKey:@"Oz"] copy];
	
	
	scaleAP = (fabs(nasion.AP - inion.AP) / fabs(Fpz.AP - Oz.AP));
	
	NSLog(@"((nasion.AP - inion.AP) / (Fpz.AP - Oz.AP)) = ((%f - %f) / (%f - %f)) = %f\n",
				nasion.AP,inion.AP,Fpz.AP,Oz.AP,scaleAP);
	
}

- (void) scaleCoordinates
{
	float			scaleAP,scaleDV;
	StereotaxCoord	*Fpz,*Oz;
	
	
	scaleAP = ((nasion.AP - inion.AP) / (Fpz.AP - Oz.AP));
	
	for (StereotaxCoord *thisElectrode in electrodes) {
		thisElectrode.AP = scaleAP * (Fpz.AP - thisElectrode.AP);
	}
}

@end
