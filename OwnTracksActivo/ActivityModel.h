//
//  Activity.h
//  
//
//  Created by Christoph Krey on 22.04.15.
//
//

#import <Foundation/Foundation.h>
#import "Activity.h"
#import "Job.h"
#import "Task.h"

@interface ActivityModel : NSObject

@property (readonly, strong, nonatomic) Activity *activity;
+ (ActivityModel *)sharedInstance;
- (BOOL)createActivityWithJob:(NSUInteger)jobIdentifier task:(NSUInteger)taskIdentifier;
- (BOOL)start;
- (BOOL)pause;
- (NSTimeInterval)actualDuration;
- (BOOL)stop;

- (NSArray *)jobs;
- (NSArray *)tasksForJob:(NSUInteger)job;
- (BOOL)addJob:(NSUInteger)jobIdentifier name:(NSString *)name;
- (BOOL)addTask:(NSUInteger)taskIdentifier inJob:(NSUInteger)jobIdentifier name:(NSString *)name;
- (Job *)getJob:(NSUInteger)jobIdentifier;
- (Task *)getTask:(NSUInteger)taskIdentifier inJob:(NSUInteger)jobIdentifier ;
- (BOOL)deleteJob:(NSUInteger)jobIdentifier;
- (BOOL)deleteTask:(NSUInteger)taskIdentifier inJob:(NSUInteger)jobIdentifier ;


@end
