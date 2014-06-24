//
//  DiscogsViewController.h
//  DTOAuth
//
//  Created by Oliver Drobnik on 6/24/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DiscogsViewController : UIViewController

- (IBAction)authorizeUser:(id)sender;
- (IBAction)accessProtectedResource:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *tokenLabel;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *appLabel;
@property (weak, nonatomic) IBOutlet UILabel *protectedResourceLabel;

@end
