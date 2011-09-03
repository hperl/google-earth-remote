//
//  MainWC.m
//  Google Earth Remote
//
//  Created by Henning Perl on 22.08.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainWC.h"

@implementation MainWC

NSString *LocationsDropType = @"LocationsDropType";


@synthesize locations;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        screenShotPath = [[[NSTemporaryDirectory() stringByAppendingPathComponent:
                          [[NSProcessInfo processInfo] globallyUniqueString]] stringByAppendingString:@".jpg"] retain];
        
        NSLog(@"Window Controller initialized");
        // compile AppleScript
        fetchLocationAS = [[NSAppleScript alloc] initWithSource:
                           @"tell application \"Google Earth\"\n\
                           GetViewInfo\n\
                           end tell"];
        saveScreenShotAS = [[NSAppleScript alloc] initWithSource:
                            [NSString stringWithFormat:
                             @"tell application \"Google Earth\"\n\
                             SaveScreenShot \"%@\"\n\
                             end tell", screenShotPath]];
        NSDictionary *error;
        if (![fetchLocationAS compileAndReturnError:&error]) {
            for (id key in error) {
                NSLog(@"compile fetch: %@: %@", key, [error objectForKey:key]);
            }
        }
        if (![saveScreenShotAS compileAndReturnError:&error]) {
            for (id key in error) {
                NSLog(@"compile screenshot: %@: %@", key, [error objectForKey:key]);
            }
        }
    }
    
    return self;
}

- (void)dealloc {
    [screenShotPath release];
    [fetchLocationAS release];
    [saveScreenShotAS release];
    [super dealloc];
}

- (NSManagedObjectContext*)managedObjectContext
{
    return [[NSApp delegate] managedObjectContext];
}

- (void)windowDidLoad
{    
    [locationsTV setDataSource:self];
    [locationsTV registerForDraggedTypes:[NSArray arrayWithObject:LocationsDropType]];
       
    [locations addObserver:self
                forKeyPath:@"selectionIndex"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];
    
    [super windowDidLoad];
}

#pragma mark locations
- (IBAction)addLocation:(id)sender
{
    NSDictionary *error = nil;
    NSError *dataError = nil;
    NSManagedObject *location;
    NSAppleEventDescriptor *results;
    
    if (!(results = [fetchLocationAS executeAndReturnError:&error])) {
        for (id key in error) {
            NSLog(@"execute fetch: %@: %@", key, [error objectForKey:key]);
        }
        return;
    }
    if (![saveScreenShotAS executeAndReturnError:&error]) {
        for (id key in error) {
            NSLog(@"screenshot: %@: %@", key, [error objectForKey:key]);
        }
        return;
    }
    
    // screenshot written to screenShotPath
    NSData *imageData = [NSData dataWithContentsOfFile:screenShotPath
                                               options:0 error:&dataError];
    if (dataError) {
        for (id key in [dataError userInfo]) {
            NSLog(@"read screenshot: %@: %@", key,
                  [[dataError userInfo] objectForKey:key]);
        }
    }
        
    location = [locations newObject];
    [location setValue:[NSString stringWithFormat:
                        @"{latitude:%@, longitude:%@, distance:%@, tilt:%@, azimuth:%@}",
                        [[results descriptorAtIndex:1] stringValue],
                        [[results descriptorAtIndex:2] stringValue],
                        [[results descriptorAtIndex:3] stringValue],
                        [[results descriptorAtIndex:4] stringValue],
                        [[results descriptorAtIndex:5] stringValue]]
                forKey:@"coordinates"];
    [location setValue:[NSNumber numberWithUnsignedLong:1+[[locations arrangedObjects] count]]
                forKey:@"order"];
    [location setValue:imageData forKey:@"imageData"];
    
    [locations addObject:location];
    [location release];
    NSFileManager* fm = [[NSFileManager alloc] init];
    [fm removeItemAtPath:screenShotPath error:NULL];
    [fm release];
}

- (IBAction)goToNextLocation:(id)sender
{
    [locations selectNext:sender];
}

- (IBAction)goToPreviousLocation:(id)sender
{
    [locations selectPrevious:sender];
}


- (IBAction)removeLocation:(id)sender {
    [locations remove:sender];
    [self renumber];
}

#pragma mark observing
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == locations && [keyPath isEqualToString:@"selectionIndex"]) {
        id location = [locations.selectedObjects objectAtIndex:0];
        NSDictionary *error = nil;
        
        goToLocationAS = [[NSAppleScript alloc] initWithSource:
                          [NSString stringWithFormat:
                           @"tell application \"Google Earth\"\n\
                           SetViewInfo %@ speed 0.2\n\
                           end tell", [location valueForKey:@"coordinates"]]];
        
        if (![goToLocationAS compileAndReturnError:&error]) {
            for (id key in error) {
                NSLog(@"compile goToLoc: %@: %@", key, [error objectForKey:key]);
            }
            return;
        }
        
        if (![goToLocationAS executeAndReturnError:&error]) {
            for (id key in error) {
                NSLog(@"execute fetch: %@: %@", key, [error objectForKey:key]);
            }
            return;
        }
    }
}


#pragma mark moving
- (NSArray*)sortDescriptors {
    if (!sortDescriptors) {
        sortDescriptors = [NSArray arrayWithObject:
                           [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES]];
    }
    return sortDescriptors;
}

- (void)renumber {
    NSInteger order = 1;
    for (id location in locations.arrangedObjects) {
        [location setValue:[NSNumber numberWithLong:order++] forKey:@"order"];
    }
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes
     toPasteboard:(NSPasteboard*)pasteboard
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pasteboard declareTypes:[NSArray arrayWithObject:LocationsDropType] owner:self];
	[pasteboard setData:data forType:LocationsDropType];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView
                validateDrop:(id < NSDraggingInfo >)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)operation
{
    if ([info draggingSource] == locationsTV) {
        if (operation == NSTableViewDropOn) {
            [aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
        }
        return NSDragOperationMove;
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)tableView:(NSTableView *)aTableView
       acceptDrop:(id < NSDraggingInfo >)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)operation
{
    NSMutableArray* array = [locations.arrangedObjects mutableCopy];
    NSArray* draggedObjs = [array objectsAtIndexes:
                            [NSKeyedUnarchiver unarchiveObjectWithData:
                             [[info draggingPasteboard] dataForType:LocationsDropType]]];

    for (NSManagedObject* draggedObj in draggedObjs) {
        NSInteger oldRow = [[draggedObj valueForKey:@"order"] integerValue];
        for (NSInteger i = oldRow; i < row; i++) {
            // dragging up => moving each obj in range down
            [[array objectAtIndex:i] setValue:[NSNumber numberWithLong:i]
                                       forKey:@"order"];
        }
        for (NSInteger i = row; i < oldRow; i++) {
            // dragging down => moving each obj in range up
            [[array objectAtIndex:i] setValue:[NSNumber numberWithLong:i+2]
                                       forKey:@"order"];
        }
        [draggedObj setValue:[NSNumber numberWithLong:row] forKey:@"order"];
        row++;
    }
    
    [locations arrangeObjects:array];
    [self renumber];
    [array release];
    return YES;
}


@end
