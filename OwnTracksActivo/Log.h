//
//  Log.h
//  OwnTracksActivo
//
//  Created by Christoph Krey on 26.04.15.
//  Copyright (c) 2015 OwnTracks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Log : NSManagedObject

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * status;

@end
