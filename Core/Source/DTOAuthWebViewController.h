//
//  DTOAuthWebViewController.h
//  DTOAuth
//
//  Created by Oliver Drobnik on 6/20/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//  Copyright (c) 2014 Kypselia. All rights reserved.
//

@class DTOAuthWebViewController;

/**
 View controller with a `UIWebView` as main view. Meant to be embedded in a navigation controller for modal presentation.
 */
@interface DTOAuthWebViewController : UIViewController

- (instancetype)initWithAuthorizationCallback:(void(^)(NSString *token, NSString *verifier, NSError *error))authorizationCallback;

/**
 Load the authorization form with a proper OAuth request, this is the request you get from step 2 in DTOAuthClient.
 */
- (void)startAuthorizationFlowWithRequest:(NSURLRequest *)request;

@end
