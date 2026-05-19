//
//  DTOAuthClient.h
//  DTOAuth
//
//  Created by Oliver Drobnik on 6/20/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//  Copyright (c) 2014 Kypselia. All rights reserved.
//

#define kDTOAuthHTTPStatusError 1
#define kDTOAuthMissingTokenError 2
#define kDTOAuthUnexpectedHTTPResponseError 3
#define kDTOAuthMissingCallbackError 4
#define kDTOAuthVerificationFailed 5

typedef NS_ENUM(NSUInteger, OAuthVersion) {
    OAuthVersion10,
    OAuthVersion10a
};

/**
 Controller for an OAuth 1.0a flow with 3 legs.
 
 1. Call -requestTokenWithCompletion: (leg 1)
 2. Get the -userTokenAuthorizationRequest and load it in webview, DTOAuthWebViewController is provided for this (leg 2)
 3. Extract the verifier returned from the OAuth provider once the user authorizes the app, DTOAuthWebViewController does that via delegate method.
 4. Call -authorizeTokenWithVerifier:completion: passing this verifier (leg 3)
 */

@interface DTOAuthClient : NSObject

/**
 Dedicated initializer. Typically you register an application with service and from there you
 receive the consumer key and consumer secret.
 */
- (instancetype)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret;

/**
 Perform the whole authorization procedure (convenience method that encapsulates all steps)
 */
- (void)authorizeUserWithPresentingViewController:(UIViewController *)presentingViewController completionBlock:(void(^)(NSString *token, NSError *error))completionBlock;


/**
 @name Request Factory
 */

/**
 The initial request for a token
 */
- (NSURLRequest *)tokenRequest;

/**
 The second request to perform following -tokenRequest, you would load this request
 in a web view so that the user can authorize the app access.
 */
- (NSURLRequest *)userTokenAuthorizationRequest;

/**
 The third request to perform with the verifier value from -userTokenAuthorizationRequest.
 */
- (NSURLRequest *)tokenAuthorizationRequestWithVerifier:(NSString *)verifier;

/**
 Generates a signed OAuth Authorization header for a given request. Parameters encoded in the URL are included in the OAuth signature.
 */
- (NSString *)authenticationHeaderForRequest:(NSURLRequest *)request;

/**
 @name Performing Requests
 */

/**
 Perform the initial request for an OAuth token
 */
- (void)requestTokenWithCompletion:(void (^)(NSError *error))completion;

/**
 Perform the final request to verify a token after the user authorized the app
 */
- (void)authorizeTokenWithVerifier:(NSString *)verifier completion:(void (^)(NSError *error))completion;

/**
 @name Properties
 */

/** 
 OAuth version (defaults to 1.0a)
 */
@property (nonatomic, assign) OAuthVersion version;

/** 
 The most recent token. You can use this to check the authorized token returned by the web view.
 @note This value is updated before the completion handler of one of the two requests.
 */
@property (nonatomic, readonly) NSString *token;


/**
 Returns yes if the bearer token was successfully exchanged for an authorization token
 */
@property (nonatomic, readonly, getter = isAuthenticated) BOOL authenticated;


#pragma mark - Endpoint URLs

/**
 The URL to request an OAuth token from
 */
@property (nonatomic, strong) NSURL *requestTokenURL;

/**
 The URL to open in a web view for authorizing a token
 */
@property (nonatomic, strong) NSURL *userAuthorizeURL;

/**
 The URL to verify an authorized token at
 */
@property (nonatomic, strong) NSURL *accessTokenURL;

/**
 If the server only replies to a specific callback URL, set it here (otherwise we'll just use a dummy callback)
 */
@property (nonatomic, strong) NSString *callbackURLString;

@end
