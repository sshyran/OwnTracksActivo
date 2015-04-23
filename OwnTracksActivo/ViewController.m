//
//  ViewController.m
//  OwnTracksActivo
//
//  Created by Christoph Krey on 22.04.15.
//  Copyright (c) 2015 OwnTracks. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Log.h"
#import "ActivityModel.h"
#import "IdPicker.h"

#import <Crashlytics/Crashlytics.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *home;
@property (weak, nonatomic) IBOutlet IdPicker *tasks;
@property (weak, nonatomic) IBOutlet IdPicker *jobs;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *play;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pause;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stop;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UITableView *logs;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.logs.delegate = self;
    self.logs.dataSource = self;
    [self.logs reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    self.timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(tick:) userInfo:nil repeats:true];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.mqttSession addObserver:self forKeyPath:@"status"
                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                 context:nil];
    [self setStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.timer invalidate];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.mqttSession removeObserver:self forKeyPath:@"status" context:nil];

    [super viewWillDisappear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    switch (appDelegate.mqttSession.status) {
        case MQTTSessionStatusConnected:
            self.home.tintColor = [UIColor greenColor];
            break;
        case MQTTSessionStatusConnecting:
        case MQTTSessionStatusCreated:
        case MQTTSessionStatusDisconnecting:
            self.home.tintColor = [UIColor yellowColor];
            break;
        case MQTTSessionStatusClosed:
        case MQTTSessionStatusError:
        default:
            self.home.tintColor = [UIColor redColor];
            break;
    }
}

- (void)setStatus {
    if ([ActivityModel sharedInstance].activity) {
        self.jobs.enabled = false;
        self.jobs.array = [[ActivityModel sharedInstance] jobs];
        self.jobs.arrayId = (int)[[ActivityModel sharedInstance].activity.jobIdentifier integerValue];
        self.tasks.enabled = false;
        self.tasks.array = [[ActivityModel sharedInstance] tasksForJob:self.jobs.arrayId];
        self.tasks.arrayId = (int)[[ActivityModel sharedInstance].activity.taskIdentifier integerValue];
        if ([ActivityModel sharedInstance].activity.lastStart) {
            self.play.enabled = false;
            self.stop.enabled = true;
            self.pause.enabled = true;
        } else {
            self.play.enabled = true;
            self.stop.enabled = false;
            self.pause.enabled = false;
        }
    } else {
        self.jobs.enabled = true;
        self.play.enabled = false;
        self.stop.enabled = false;
        self.pause.enabled = false;
        if (self.jobs.arrayId == 0) {
            self.tasks.enabled = false;
        } else {
            self.tasks.enabled = true;
        }
        if (self.tasks.arrayId == 0) {
            self.play.enabled = false;
        } else {
            self.play.enabled = true;
        }
    }
}

- (IBAction)jobStarting:(IdPicker *)sender {
    self.jobs.array = [[ActivityModel sharedInstance] jobs];
}

- (IBAction)job:(IdPicker *)sender {
    self.tasks.arrayId = 0;
    [self setStatus];
}

- (IBAction)taskStarting:(IdPicker *)sender {
    self.tasks.array = [[ActivityModel sharedInstance] tasksForJob:self.jobs.arrayId];
}

- (IBAction)task:(IdPicker *)sender {
    [self setStatus];
}

- (IBAction)home:(UIBarButtonItem *)sender {
    NSMutableDictionary *config = [[NSMutableDictionary alloc] init];
    for (NSString *key in @[@"Publish",
                            @"Host",
                            @"Port",
                            @"SSL",
                            @"ClientId",
                            @"UserName",
                            @"Password",
                            @"Subscription",
                            @"KeepDays"]) {
        [config setObject:[[NSUserDefaults standardUserDefaults] objectForKey:key] forKey:key];
    }
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [config setObject:appDelegate.mqttError ? [appDelegate.mqttError description] : @"-" forKey:@"MQTTError"];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Configuration"
                                                        message:[config description]
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Reconnect", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate reconnect];
    }
}

- (void)tick:(NSTimer *)timer {
    if ([ActivityModel sharedInstance].activity) {
        if ([ActivityModel sharedInstance].activity.lastStart) {
            self.status.text = [NSString stringWithFormat:@"working since %.0f seconds",
                                [[ActivityModel sharedInstance] actualDuration]];
        } else {
            self.status.text = [NSString stringWithFormat:@"work paused after %.0f seconds",
                                [[ActivityModel sharedInstance] actualDuration]];
        }
    } else {
        self.status.text = @"";
    }
}

- (IBAction)stop:(UIBarButtonItem *)sender {
    [[ActivityModel sharedInstance] stop];
    [self setStatus];
}
- (IBAction)pause:(UIBarButtonItem *)sender {
    [[ActivityModel sharedInstance] pause];
    [self setStatus];
}

- (IBAction)play:(UIBarButtonItem *)sender {
    if (![ActivityModel sharedInstance].activity) {
        [[ActivityModel sharedInstance] createActivityWithJob:self.jobs.arrayId task:self.tasks.arrayId];
    }
    [[ActivityModel sharedInstance] start];
    [self setStatus];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[self fetchRequestForTableView]
                                                                                                managedObjectContext:appDelegate.managedObjectContext
                                                                                                  sectionNameKeyPath:nil
                                                                                                           cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;


    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle     the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        CLSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.logs beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.logs insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.logs deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.logs insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.logs deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [self.logs reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeMove:
            [self.logs deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.logs insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.logs endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"log" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];

        NSError *error = nil;
        if (![context save:&error]) {
            CLSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


- (NSFetchRequest *)fetchRequestForTableView
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Log"
                                              inManagedObjectContext:appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor1];

    [fetchRequest setSortDescriptors:sortDescriptors];

    return fetchRequest;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return [NSString stringWithFormat:@"Messages"];
    } else {
        return nil;
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Log *log = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:log.timestamp dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    
    cell.textLabel.text = log.content;
}

@end
