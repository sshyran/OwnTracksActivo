//
//  Activity.m
//
//
//  Created by Christoph Krey on 22.04.15.
//
//

#import "ActivityModel.h"
#import "AppDelegate.h"
#import "Log.h"

static ActivityModel *theActivityModel;

@interface ActivityModel()
@property (strong, nonatomic) Activity *activity;

@end

@implementation ActivityModel
+ (ActivityModel *)sharedInstance {
    if (!theActivityModel) {
        theActivityModel = [[ActivityModel alloc] init];
    }
    return theActivityModel;
}

- (ActivityModel *)init {
    self = [super init];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Activity"];

    NSError *error = nil;

    NSArray *matches = [appDelegate.managedObjectContext executeFetchRequest:request
                                                                       error:&error];

    if (matches && matches.count > 0) {
        self.activity = (Activity *)matches[0];
    }
    return self;
}

- (BOOL)createActivityWithJob:(NSUInteger)jobIdentifier task:(NSUInteger)taskIdentifier {

    if (!self.activity) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        self.activity = [NSEntityDescription insertNewObjectForEntityForName:@"Activity"
                                                      inManagedObjectContext:appDelegate.managedObjectContext];
        self.activity.jobIdentifier = [NSNumber numberWithUnsignedInteger:jobIdentifier];
        self.activity.taskIdentifier = [NSNumber numberWithUnsignedInteger:taskIdentifier];
        self.activity.lastStart = nil;
        self.activity.duration = [NSNumber numberWithDouble:0.0];
        [self log:[NSString stringWithFormat:@"Created %@/%@",
                   self.activity.jobIdentifier,
                   self.activity.taskIdentifier]];
        return true;
    } else {
        return false;
    }
}

- (BOOL)start {
    if (self.activity) {
        if (self.activity.lastStart == nil) {
            self.activity.lastStart = [NSDate date];
            [self log:[NSString stringWithFormat:@"Started %@/%@",
                       [self getJob:[self.activity.jobIdentifier integerValue]].name,
                       [self getTask:[self.activity.taskIdentifier integerValue]
                               inJob:[self.activity.jobIdentifier integerValue]].name]];
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [appDelegate.mqttSession publishData:[[NSString stringWithFormat:@"%@ %@",
                                                   self.activity.jobIdentifier,
                                                   self.activity.taskIdentifier] dataUsingEncoding:NSUTF8StringEncoding]
                                         onTopic:[[NSUserDefaults standardUserDefaults] stringForKey:@"Publish"]
                                                  retain:true
                                                  qos:MQTTQosLevelExactlyOnce];
            [appDelegate.mqttSession publishData:[[NSString stringWithFormat:@"%@ %@",
                                                   self.activity.jobIdentifier,
                                                   self.activity.taskIdentifier] dataUsingEncoding:NSUTF8StringEncoding]
                                         onTopic:[NSString stringWithFormat:@"%@/%.0f",
                                                  [[NSUserDefaults standardUserDefaults] stringForKey:@"Publish"],
                                                  [[NSDate date] timeIntervalSince1970]]
                                          retain:true
                                             qos:MQTTQosLevelAtLeastOnce];

            return true;
        } else  {
            return false;
        }
    } else {
        return false;
    }
}

- (BOOL)pause {
    if (self.activity) {
        if (self.activity.lastStart != nil) {
            NSTimeInterval duration = [self.activity.duration doubleValue];
            duration += [[NSDate date] timeIntervalSinceDate:self.activity.lastStart];
            self.activity.duration = [NSNumber numberWithDouble:duration];
            self.activity.lastStart = nil;
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [appDelegate.mqttSession publishData:nil
                                         onTopic:[[NSUserDefaults standardUserDefaults] stringForKey:@"Publish"]
                                          retain:true
                                             qos:MQTTQosLevelExactlyOnce];
            [appDelegate.mqttSession publishData:[@"0 0" dataUsingEncoding:NSUTF8StringEncoding]
                                         onTopic:[NSString stringWithFormat:@"%@/%.0f",
                                                  [[NSUserDefaults standardUserDefaults] stringForKey:@"Publish"],
                                                  [[NSDate date] timeIntervalSince1970]]
                                          retain:true
                                             qos:MQTTQosLevelAtLeastOnce];
            [self log:[NSString stringWithFormat:@"Paused %@/%@ after %.0f seconds",
                       [self getJob:[self.activity.jobIdentifier integerValue]].name,
                       [self getTask:[self.activity.taskIdentifier integerValue]
                               inJob:[self.activity.jobIdentifier integerValue]].name,
                       [self.activity.duration doubleValue]
                       ]
             ];
            return true;
        } else  {
            return false;
        }
    } else {
        return false;
    }

}

- (NSTimeInterval)actualDuration {
    if (self.activity) {
        NSTimeInterval duration = [self.activity.duration doubleValue];
        if (self.activity.lastStart != nil) {
            duration += [[NSDate date] timeIntervalSinceDate:self.activity.lastStart];
        }
        return duration;
    } else {
        return 0;
    }
    
}

- (BOOL)stop {
    if (self.activity) {
        if ([self pause]) {
            [self log:[NSString stringWithFormat:@"Stopped %@/%@ after %.0f seconds",
                       [self getJob:[self.activity.jobIdentifier integerValue]].name,
                       [self getTask:[self.activity.taskIdentifier integerValue]
                               inJob:[self.activity.jobIdentifier integerValue]].name,
                       [self.activity.duration doubleValue]
                       ]
             ];
             self.activity = nil;
            return true;
        } else  {
            return false;
        }
    } else {
        return false;
    }
}

- (void)log:(NSString *)content {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    Log *log = [NSEntityDescription insertNewObjectForEntityForName:@"Log"
                                             inManagedObjectContext:appDelegate.managedObjectContext];
    log.timestamp = [NSDate date];
    log.content = content;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Log"];
    NSDate *oldDays = [NSDate dateWithTimeIntervalSinceNow:
                       -[[NSUserDefaults standardUserDefaults] integerForKey:@"KeepDays"] * 24 * 3600];
    request.predicate = [NSPredicate predicateWithFormat:@"timestamp < %@", oldDays];
    
    NSArray *matches = [appDelegate.managedObjectContext executeFetchRequest:request error:nil];
    if (matches) {
        for (log in matches) {
            [appDelegate.managedObjectContext deleteObject:log];
        }
    }
    
    [appDelegate saveContext];
}

- (NSArray *)jobs {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Job"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];

    NSError *error = nil;

    NSArray *matches = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];

    return matches;

}

- (NSArray *)tasksForJob:(NSUInteger)job {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"jobIdentifier = %@", [NSNumber numberWithUnsignedInteger:job]];

    NSError *error = nil;

    NSArray *matches = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];

    return matches;
}

- (BOOL)addJob:(NSUInteger)jobIdentifier name:(NSString *)name {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    Job *job = [self getJob:jobIdentifier];
    if (job) {
        job.name = name;
    } else {
        job = [NSEntityDescription insertNewObjectForEntityForName:@"Job"
                                                 inManagedObjectContext:appDelegate.managedObjectContext];
        job.identifier = [NSNumber numberWithUnsignedInteger:jobIdentifier];
        job.name = name;
    }
    [appDelegate saveContext];
    return true;
}

- (BOOL)addTask:(NSUInteger)taskIdentifier inJob:(NSUInteger)jobIdentifier name:(NSString *)name {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    Task *task = [self getTask:taskIdentifier inJob:jobIdentifier];
    if (task) {
        task.name = name;
    } else {
        task = [NSEntityDescription insertNewObjectForEntityForName:@"Task"
                                                inManagedObjectContext:appDelegate.managedObjectContext];
        task.identifier = [NSNumber numberWithUnsignedInteger:taskIdentifier];
        task.jobIdentifier = [NSNumber numberWithUnsignedInteger:jobIdentifier];
        task.name = name;
    }
    [appDelegate saveContext];
    return true;
}

- (Job *)getJob:(NSUInteger)jobIdentifier {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Job"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", [NSNumber numberWithUnsignedInteger:jobIdentifier]];
    NSArray *matches = [appDelegate.managedObjectContext executeFetchRequest:request error:nil];
    return matches ? matches.count ? matches[0] : nil: nil;
}

- (Task *)getTask:(NSUInteger)taskIdentifier inJob:(NSUInteger)jobIdentifier {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier = %@ and jobIdentifier = %@",
                         [NSNumber numberWithUnsignedInteger:taskIdentifier],
                         [NSNumber numberWithUnsignedInteger:jobIdentifier]];
    NSArray *matches = [appDelegate.managedObjectContext executeFetchRequest:request error:nil];
    return matches ? matches.count ? matches[0] : nil: nil;
}

- (BOOL)deleteJob:(NSUInteger)jobIdentifier {
    Job *job = [self getJob:jobIdentifier];
    if (job) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate.managedObjectContext deleteObject:job];
        [appDelegate saveContext];
        return true;
    } else {
        return false;
    }
}

- (BOOL)deleteTask:(NSUInteger)taskIdentifier inJob:(NSUInteger)jobIdentifier {
    Task *task = [self getTask:taskIdentifier inJob:jobIdentifier];
    if (task) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate.managedObjectContext deleteObject:task];
        [appDelegate saveContext];
        return true;
    } else {
        return false;
    }
}

@end
