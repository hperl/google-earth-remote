//
//  MainWC.h
//  Google Earth Remote
//
//  Created by Henning Perl on 22.08.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainWC : NSWindowController <NSTableViewDataSource> {
    NSArrayController *locations;
    NSAppleScript *fetchLocationAS, *goToLocationAS, *saveScreenShotAS;
    IBOutlet NSTableColumn *locationsTC;
    IBOutlet NSTableView *locationsTV;
    
    NSArray *sortDescriptors;
    
    NSString *screenShotPath;
}

@property (assign) IBOutlet NSArrayController *locations;
@property (readonly) NSManagedObjectContext *managedObjectContext;
@property (readonly) NSArray *sortDescriptors;

- (IBAction)addLocation:(id)sender;
- (IBAction)removeLocation:(id)sender;
- (IBAction)goToNextLocation:(id)sender;
- (IBAction)goToPreviousLocation:(id)sender;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context;

- (void)renumber;

@end