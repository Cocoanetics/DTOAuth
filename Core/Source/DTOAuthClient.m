//
//  DTOAuth.m
//  OAuthTest
//
//  Created by Oliver Drobnik on 6/20/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTOAuthClient.h"
#import "DTOAuthFunctions.h"

#import <CommonCrypto/CommonHMAC.h>

// callback URL is never seen by anybody, so we use this only internally
#define CALL_BACK_URL @"http://www.whatever.org"

@implementation DTOAuthClient
{
	// consumer info set in init
	NSString *_consumerKey;
	NSString *_consumerSecret;
	
	// token info stored as result of performing requests
	NSString *_token;
	NSString *_tokenSecret;
}

#pragma mark - Initializer

- (instancetype)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret
{
	self = [super init];
	
	if (self)
	{
		_consumerKey = [consumerKey copy];
		_consumerSecret = [consumerSecret copy];
	}
	
	return self;
}

#pragma mark - Helpers

- (NSString *)_timestamp
{
	NSTimeInterval t = [[NSDate date] timeIntervalSince1970];
	return [NSString stringWithFormat:@"%u", (int)t];
}

- (NSString *)_nonce
{
	NSUUID *uuid = [NSUUID UUID];
	return [uuid UUIDString];
}

- (NSString *)_urlEncodedString:(NSString *)string
{
	// we need to be stricter than usual with the URL encoding
	NSMutableCharacterSet *chars = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
	[chars removeCharactersInString:@"!*'();:@&=+$,/?%#[]"];
	
	return 	[string stringByAddingPercentEncodingWithAllowedCharacters:chars];
}

- (NSString *)_stringFromParamDictionary:(NSDictionary *)dictionary
{
	NSMutableArray *keyValuePairs = [NSMutableArray array];
	NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	for (NSString *key in sortedKeys)
	{
		NSString *encKey = [self _urlEncodedString:key];
		NSString *encValue = [self _urlEncodedString:[dictionary objectForKey:key]];
		
		NSString *pair = [NSString stringWithFormat:@"%@=%@", encKey, encValue];
		[keyValuePairs addObject:pair];
	}
	
	return [keyValuePairs componentsJoinedByString:@"&"];
}

// helper for setting the token from unit test
- (void)_setToken:(NSString *)token secret:(NSString *)secret
{
	_token = token;
	_tokenSecret = secret;
}

#pragma mark - Creating the Authorization Header

// assembles the dictionary of the standard oauth parameters for creating the signature
- (NSDictionary *)_authorizationParametersWithExtraParameters:(NSDictionary *)extraParams
{
	NSParameterAssert(_consumerKey);
	
	NSMutableDictionary *authParams = [@{@"oauth_consumer_key" : _consumerKey,
													 @"oauth_nonce" : [self _nonce],
													 @"oauth_timestamp" : [self _timestamp],
													 @"oauth_version" : @"1.0",
													 @"oauth_signature_method" : @"HMAC-SHA1"} mutableCopy];
	
	if (_token)
	{
		authParams[@"oauth_token"] = _token;
	}
	
	if ([extraParams count])
	{
		[authParams addEntriesFromDictionary:extraParams];
	}
	
	return [authParams copy];
}

// creates the OAuth Authorization header for a given request and set of auth parameters
- (NSString *)_authorizationHeaderForRequest:(NSURLRequest *)request authParams:(NSDictionary *)authParams
{
	// mutable version of the OAuth header contents to add the signature
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:authParams];
	
	NSString *signature = [self _signatureForMethod:[request HTTPMethod]
														  scheme:[request.URL scheme]
															 host:[request.URL host]
															 path:[request.URL path]
													 authParams:authParams];
	
	tmpDict[@"oauth_signature"] = signature;
	
	// build Authorization header
	NSMutableString *tmpStr = [NSMutableString string];
	NSArray *sortedKeys = [[tmpDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
	[tmpStr appendString:@"OAuth "];
	
	NSMutableArray *pairs = [NSMutableArray array];
	
	for (NSString *key in sortedKeys)
	{
		NSMutableString *pairStr = [NSMutableString string];
		
		NSString *encKey = [self _urlEncodedString:key];
		NSString *encValue = [self _urlEncodedString:[tmpDict objectForKey:key]];
		
		[pairStr appendString:encKey];
		[pairStr appendString:@"=\""];
		[pairStr appendString:encValue];
		[pairStr appendString:@"\""];
		
		[pairs addObject:pairStr];
	}
	
	[tmpStr appendString:[pairs componentsJoinedByString:@", "]];
	
	// immutable version
	return [tmpStr copy];
}

// constructs the cryptographic signature for this combination of parameters
- (NSString *)_signatureForMethod:(NSString *)method scheme:(NSString *)scheme host:(NSString *)host path:(NSString *)path authParams:(NSDictionary *)authParams
{
	NSString *authParamString = [self _stringFromParamDictionary:authParams];
	NSString *signatureBase = [NSString stringWithFormat:@"%@&%@%%3A%%2F%%2F%@%@&%@",
										[method uppercaseString],
										[scheme lowercaseString],
										[self _urlEncodedString:[host lowercaseString]],
										[self _urlEncodedString:path],
										[self _urlEncodedString:authParamString]];
	
	NSString *signatureSecret = [NSString stringWithFormat:@"%@&%@", _consumerSecret, _tokenSecret ?: @""];
	NSData *sigbase = [signatureBase dataUsingEncoding:NSUTF8StringEncoding];
	NSData *secret = [signatureSecret dataUsingEncoding:NSUTF8StringEncoding];
	
	// use CommonCrypto to create a SHA1 digest
	uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
	CCHmacContext cx;
	CCHmacInit(&cx, kCCHmacAlgSHA1, secret.bytes, secret.length);
	CCHmacUpdate(&cx, sigbase.bytes, sigbase.length);
	CCHmacFinal(&cx, digest);
	
	// convert to NSData and return base64-string
	NSData *digestData = [NSData dataWithBytes:&digest length:CC_SHA1_DIGEST_LENGTH];
	return [digestData base64EncodedStringWithOptions:0];
}

#pragma mark - Request Factory

// builds a request to the given URL, method and additional parameters
- (NSURLRequest *)_authorizedRequestWithURL:(NSURL *)URL extraParameters:(NSDictionary *)extraParameters
{
	NSDictionary *authParams = [self _authorizationParametersWithExtraParameters:extraParameters];
	
	// create request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	request.HTTPMethod = @"POST"; // token requests should always be POST
	
	// add the OAuth Authorization
	NSString *authHeader = [self _authorizationHeaderForRequest:request authParams:authParams];
	[request setValue:authHeader forHTTPHeaderField:@"Authorization"];
	
	// return immutable version
	return [request copy];
}

- (NSURLRequest *)tokenRequest
{
	// consumer key and secret must be set
	NSParameterAssert(_consumerKey);
	NSParameterAssert(_consumerSecret);
	
	NSURL *requestTokenURL = [self requestTokenURL];
	NSParameterAssert(requestTokenURL);
	
	// create authorized request
	NSDictionary *extraParams = @{@"oauth_callback" : CALL_BACK_URL};
	return [self _authorizedRequestWithURL:requestTokenURL extraParameters:extraParams];
}

- (NSURLRequest *)userTokenAuthorizationRequest
{
	// token must be present
	NSParameterAssert(_token);
	
	NSURL *userAuthorizeURL = [self userAuthorizeURL];
	NSParameterAssert(userAuthorizeURL);
	
	NSString *callback = [self _urlEncodedString:CALL_BACK_URL];
	NSString *str = [NSString stringWithFormat:@"%@?oauth_token=%@&oauth_callback=%@", [userAuthorizeURL absoluteString], _token, callback];
	NSURL *url = [NSURL URLWithString:str];
	
	return [NSURLRequest requestWithURL:url];
}

- (NSURLRequest *)tokenAuthorizationRequestWithVerifier:(NSString *)verifier
{
	// consumer key and secret must be set
	NSParameterAssert(_consumerKey);
	NSParameterAssert(_consumerSecret);
	
	// token and token secrent must be present
	NSParameterAssert(_token);
	NSParameterAssert(_tokenSecret);
	
	// verifier must be present
	NSParameterAssert(verifier);
	
	NSURL *accessTokenURL = [self accessTokenURL];
	NSParameterAssert(accessTokenURL);
	
	// additional params
	NSDictionary *params = @{@"oauth_callback" : CALL_BACK_URL,
									 @"oauth_verifier": verifier};
	
	return [self _authorizedRequestWithURL:accessTokenURL extraParameters:params];
}

- (NSString *)authenticationHeaderForRequest:(NSURLRequest *)request
{
	NSMutableDictionary *extraParams = [NSMutableDictionary dictionary];
	
	NSString *query = [request.URL query];
	
	// parameters in the URL query string need to be considered for the signature
	if ([query length])
	{
		[extraParams addEntriesFromDictionary:DTOAuthDictionaryFromQueryString(query)];
	}
	
	
	
	NSDictionary *authParams = [self _authorizationParametersWithExtraParameters:extraParams];
	return [self _authorizationHeaderForRequest:request authParams:authParams];
}

#pragma mark - OAuth URLs

- (NSURL *)requestTokenURL
{
	return nil;
}

- (NSURL *)userAuthorizeURL
{
	return nil;
}

- (NSURL *)accessTokenURL
{
	return nil;
}


#pragma mark - Performing the Token Requests

// performs the request for leg 1 or leg 3 and stores the token info if successful
- (void)_performAuthorizedRequest:(NSURLRequest *)request completion:(void (^)(NSDictionary *result, NSError *error))completion
{
	NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
	NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		if (error)
		{
			if (completion)
			{
				completion(nil, error);
			}
			
			return;
		}
		
		NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		if ([response isKindOfClass:[NSHTTPURLResponse class]])
		{
			NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
			
			// cannot validate the Content-Type because Twitter incorrectly returns text/html
			
			if ([httpResponse statusCode]!=200)
			{
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey : s};
				NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:1 userInfo:userInfo];
				
				if (completion)
				{
					completion(nil, error);
				}
				
				return;
			}
		}
		else
		{
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Didn't receive expected HTTP response."};
			NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:3 userInfo:userInfo];
			
			if (completion)
			{
				completion(nil, error);
			}
			
			return;
		}
		
		NSDictionary *result = DTOAuthDictionaryFromQueryString(s);
		
		NSString *token = result[@"oauth_token"];
		NSString *tokenSecret = result[@"oauth_token_secret"];
		
		if (![token length] || ![tokenSecret length])
		{
			[self _setToken:nil secret:nil];
			
			if (completion)
			{
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Missing token info in response"};
				NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:2 userInfo:userInfo];
				completion(nil, error);
			}
			
			return;
		}
		
		// all is fine store the token info
		[self _setToken:token secret:tokenSecret];
		
		if (completion)
		{
			completion(result, nil);
		}
	}];
	
	[task resume];
}

// performs leg 1
- (void)requestTokenWithCompletion:(void (^)(NSError *error))completion;
{
	// wipe previous token
	[self _setToken:nil secret:nil];
	
	// new request
	NSURLRequest *request = [self tokenRequest];
	
	[self _performAuthorizedRequest:request completion:^(NSDictionary *result, NSError *error) {
		
		if (error)
		{
			if (completion)
			{
				completion(error);
			}
			return;
		}
		
		NSString *callbackConfirmation = result[@"oauth_callback_confirmed"];
		
		// according to spec this value must be present
		if (![callbackConfirmation isEqualToString:@"true"])
		{
			[self _setToken:nil secret:nil];
			
			if (completion)
			{
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Missing callback confirmation in response"};
				NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:4 userInfo:userInfo];
				completion(error);
			}
			
			return;
		}
		
		if (completion)
		{
			completion(nil);
		}
	}];
}

// performs leg 3
- (void)authorizeTokenWithVerifier:(NSString *)verifier completion:(void (^)(NSError *error))completion
{
	NSURLRequest *request = [self tokenAuthorizationRequestWithVerifier:verifier];
	
	[self _performAuthorizedRequest:request completion:^(NSDictionary *result, NSError *error) {
		if (completion)
		{
			completion(nil);
		}
	}];
}

@end
