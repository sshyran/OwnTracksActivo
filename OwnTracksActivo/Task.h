//
//  Task.h
//  OwnTracksActivo
//
//  Created by Christoph Krey on 22.04.15.
//  Copyright (c) 2015 OwnTracks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Task : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * jobIdentifier;
@property (nonatomic, retain) NSString * name;

@end