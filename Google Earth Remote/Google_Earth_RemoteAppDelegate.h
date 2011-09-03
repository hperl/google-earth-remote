//
//  Google_Earth_RemoteAppDelegate.h
//  Google Earth Remote
//
//  Created by Henning Perl on 22.08.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RemoteControl, MainWC;

@interface Google_Earth_RemoteAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    NSPersistentStoreCoordinator *__persistentStoreCoordinator;
    NSManagedObjectModel *__managedObjectModel;
    NSManagedObjectContext *__managedObjectContext;
    
    RemoteControl *remoteControl;
    
    MainWC *mainWC;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSArrayController *locations;

@property (retain) NSWindowController *mainWC;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (retain) RemoteControl *remoteControl;

- (IBAction)saveAction:(id)sender;

@end
