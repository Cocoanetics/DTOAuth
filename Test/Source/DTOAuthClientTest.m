//
//  Unit_Tests.m
//  Unit Tests
//
//  Created by Oliver Drobnik on 6/25/14.
//  Copyright (c) 2014 ProductLayer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DTOAuthClient.h"
#import "DTOAuthFunctions.h"


// internal methods of DTOAuthClient we are needing to access for our tests
@interface DTOAuthClient (Test)

- (NSDictionary *)_authorizationParametersWithExtraParameters:(NSDictionary *)extraParams;
- (NSString *)_signatureForMethod:(NSString *)method scheme:(NSString *)scheme host:(NSString *)host path:(NSString *)path signatureParams:(NSDictionary *)signatureParams;
- (void)_setToken:(NSString *)token secret:(NSString *)secret;
@property (nonatomic, copy) NSString *(^timestampProvider)(void);
@property (nonatomic, copy) NSString *(^nonceProvider)(void);

@end


@interface DTOAuthClientTest : XCTestCase
@end

@implementation DTOAuthClientTest

// client configured for Twitter's example at https://dev.twitter.com/docs/auth/creating-signature

- (DTOAuthClient *)_twitterClient
{
	NSString *consumerKey = @"xvz1evFS4wEEPTGEFPHBog";
	NSString *consumerSecret = @"kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw";
	
	NSString *token = @"370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb";
	NSString *tokenSecret = @"LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE";
	
	DTOAuthClient *client = [[DTOAuthClient alloc] initWithConsumerKey:consumerKey
																		 consumerSecret:consumerSecret];
	[client _setToken:token
				  secret:tokenSecret];
	
	client.timestampProvider = ^{
		return @"1318622958";
	};
	
	client.nonceProvider = ^{
		return @"kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg";
	};
	
	return client;
}

- (void)testCollectingAuthParams
{
	DTOAuthClient *client = [self _twitterClient];

	NSDictionary *params = [client _authorizationParametersWithExtraParameters:nil];
	
	id oauth_consumer_key = params[@"oauth_consumer_key"];
	XCTAssertNotNil(oauth_consumer_key, @"oauth_consumer_key nil");
	XCTAssertTrue([oauth_consumer_key isEqualToString:@"xvz1evFS4wEEPTGEFPHBog"], @"Wrong consumer key");

	id oauth_nonce = params[@"oauth_nonce"];
	XCTAssertNotNil(oauth_nonce, @"oauth_nonce is nil");
	XCTAssertTrue([oauth_nonce isEqualToString:@"kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg"], @"Wrong nonce");

	id oauth_signature_method = params[@"oauth_signature_method"];
	XCTAssertNotNil(oauth_signature_method, @"oauth_signature_method nil");
	XCTAssertTrue([oauth_signature_method isEqualToString:@"HMAC-SHA1"], @"Wrong signature method");

	id oauth_timestamp = params[@"oauth_timestamp"];
	XCTAssertNotNil(oauth_timestamp, @"oauth_timestamp nil");
	XCTAssertTrue([oauth_timestamp isEqualToString:@"1318622958"], @"Wrong timestamp for this test");
	
	id oauth_token = params[@"oauth_token"];
	XCTAssertNotNil(oauth_token, @"oauth_token is nil");
	
	id oauth_version = params[@"oauth_version"];
	XCTAssertNotNil(oauth_version, @"oauth_version nil");
	XCTAssertTrue([oauth_version isEqualToString:@"1.0"], @"Wrong OAuth version");
}


- (void)testSignature
{
	DTOAuthClient *client = [self _twitterClient];
	
	NSString *method = @"POST";
	NSString *scheme = @"https";
	NSString *host = @"api.twitter.com";
	NSString *path = @"/1/statuses/update.json";
	
	NSDictionary *extraParams = @{@"include_entities": @"true",
											@"status": @"Hello Ladies + Gentlemen, a signed OAuth request!"};
	
	NSDictionary *params = [client _authorizationParametersWithExtraParameters:extraParams];
	
	NSString *signature = [client _signatureForMethod:method
															 scheme:scheme
																host:host
																path:path
														signatureParams:params];
	
	NSString *expectedSig = @"tnnArxj06cWHq44gCs1OSKk/jLY=";
	
	XCTAssertTrue([expectedSig isEqualToString:signature], @"Invalid Signature");
}

- (void)testParametersInURLAndPost
{
	DTOAuthClient *client = [self _twitterClient];
	
	NSURL *URL = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json?include_entities=true"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	request.HTTPMethod = @"POST";
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	NSString *body = @"status=Hello%20Ladies%20%2b%20Gentlemen%2c%20a%20signed%20OAuth%20request%21";
	request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
	
	NSString *authHeader = [client authenticationHeaderForRequest:request];
	XCTAssertNotNil(authHeader, @"Header is nil");
	
	XCTAssertTrue([authHeader hasPrefix:@"OAuth"], @"Wrong prefix");
	
	NSRange rangeOfSignature = [authHeader rangeOfString:@"tnnArxj06cWHq44gCs1OSKk%2FjLY%3D"];
	XCTAssertNotEqual(rangeOfSignature.location, NSNotFound, @"Wrong signature");
	
	NSRange rangeOfURLParam = [authHeader rangeOfString:@"include_entities"];
	XCTAssertEqual(rangeOfURLParam.location, NSNotFound, @"URL param should not be present in OAuth header");
	
	NSRange rangeOfPostParam = [authHeader rangeOfString:@"status"];
	XCTAssertEqual(rangeOfPostParam.location, NSNotFound, @"Post param should not be present in OAuth header");
}

@end
