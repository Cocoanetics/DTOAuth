//
//  WebViewController.m
//  OAuthTest
//
//  Created by Oliver Drobnik on 6/20/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTOAuthWebViewController.h"
#import "DTOAuthFunctions.h"

@interface DTOAuthWebViewController () <UIWebViewDelegate>

@end

@implementation DTOAuthWebViewController
{
	NSURLRequest *authorizationRequest;
	
	NSURL *_callbackURL;
	void (^_completionHandler)(BOOL isAuthenticated, NSString *verifier);
}

#pragma mark - Initialization

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}

- (void)loadView
{
	UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	webView.delegate = self;
	self.view = webView;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancelButton;
}

#pragma mark - Helpers

- (UIWebView *)webView
{
	return (UIWebView *)self.view;
}

// checks if the passed URL is indeed the callback URL
- (BOOL)isCallbackURL:(NSURL *)URL
{
	if (![URL.host isEqualToString:_callbackURL.host])
	{
		return NO;
	}
	
	NSString *path = [_callbackURL.path length]?_callbackURL.path:@"/";
	
	if (![URL.path isEqualToString:path])
	{
		return NO;
	}
	
	if (![URL.scheme isEqualToString:_callbackURL.scheme])
	{
		return NO;
	}
	
	return YES;
}

// informs the delegate based on the result
- (void)handleCallbackURL:(NSURL *)URL
{
	NSString *query = [URL query];
	NSDictionary *params = DTOAuthDictionaryFromQueryString(query);
	
	NSString *token = params[@"oauth_token"];
	NSString *verifier = params[@"oauth_verifier"];
	
	if ([verifier length])
	{
		if ([_authorizationDelegate respondsToSelector:@selector(authorizationWasGranted:forToken:withVerifier:)])
		{
			[_authorizationDelegate authorizationWasGranted:self forToken:token withVerifier:verifier];
		}
		
		if (_completionHandler)
		{
			_completionHandler(YES, verifier);
		}
	}
	else
	{
		if ([_authorizationDelegate respondsToSelector:@selector(authorizationWasDenied:)])
		{
			[_authorizationDelegate authorizationWasDenied:self];
		}
		
		if (_completionHandler)
		{
			_completionHandler(NO, nil);
		}
	}
	
	_completionHandler = nil;
}

#pragma mark - Public Methods

- (void)startAuthorizationFlowWithRequest:(NSURLRequest *)request completion:(void (^)(BOOL isAuthenticated, NSString *verifier))completion
{
	if (completion)
	{
		_completionHandler = [completion copy];
	}
	
	authorizationRequest = request;
	
	NSString *query = [request.URL query];
	NSDictionary *params = DTOAuthDictionaryFromQueryString(query);
	
	_callbackURL = [NSURL URLWithString:params[@"oauth_callback"]];
	
	[self.webView loadRequest:authorizationRequest];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// set nav bar title to title of
	self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (![self isCallbackURL:request.URL])
	{
		return YES;
	}
	
	[self handleCallbackURL:request.URL];
	
	return NO;
}

#pragma mark - Actions

- (void)cancel:(id)sender
{
	[_authorizationDelegate authorizationWasDenied:self];
	
	if (_completionHandler)
	{
		_completionHandler(NO, nil);
	}
}

@end
