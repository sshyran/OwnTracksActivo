//
//  AppDelegate.h
//  OwnTracksActivo
//
//  Created by Christoph Krey on 22.04.15.
//  Copyright (c) 2015 OwnTracks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MQTTClient/MQTTClient.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, MQTTSessionDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (readonly, strong, nonatomic) MQTTSession *mqttSession;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

