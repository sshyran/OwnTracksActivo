//
//  IdPicker.h
//  Wegeheld
//
//  Created by Christoph Krey on 18.02.15.
//  Copyright (c) 2015 OwnTracks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IdPicker : UITextField<UIPickerViewDataSource,UIPickerViewDelegate>
@property (strong, nonatomic) NSArray *array;
@property (nonatomic) int arrayId;

@end
