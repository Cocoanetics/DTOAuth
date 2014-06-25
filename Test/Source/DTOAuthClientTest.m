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

// private helpers to be tested
@interface DTOAuthClient (Test)
- (NSString *)_signatureForMethod:(NSString *)method scheme:(NSString *)scheme host:(NSString *)host path:(NSString *)path authParams:(NSDictionary *)authParams;
- (void)_setToken:(NSString *)token secret:(NSString *)secret;

@end



@interface DTOAuthClientTest : XCTestCase

@end

@implementation DTOAuthClientTest

// from: https://dev.twitter.com/docs/auth/creating-signature
- (void)testSignature
{
	NSString *consumerKey = @"xvz1evFS4wEEPTGEFPHBog";
	NSString *consumerSecret = @"kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw";
	
	NSString *token = @"370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb";
	NSString *tokenSecret = @"LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE";
	
	DTOAuthClient *client = [[DTOAuthClient alloc] initWithConsumerKey:consumerKey
																		 consumerSecret:consumerSecret];
	[client _setToken:token
				  secret:tokenSecret];
	
	NSString *method = @"POST";
	NSString *scheme = @"https";
	NSString *host = @"api.twitter.com";
	NSString *path = @"/1/statuses/update.json";
	NSDictionary *authParams = @{@"include_entities": @"true",
										  @"status": @"Hello Ladies + Gentlemen, a signed OAuth request!",
										  @"oauth_consumer_key": consumerKey,
										  @"oauth_nonce": @"kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg",
										  @"oauth_signature_method": @"HMAC-SHA1",
										  @"oauth_timestamp": @"1318622958",
										  @"oauth_token" : token,
										  @"oauth_version": @"1.0"};
	
	
	NSString *signature = [client _signatureForMethod:method
															 scheme:scheme
																host:host
																path:path
														authParams:authParams];
	
	NSString *expectedSig = @"tnnArxj06cWHq44gCs1OSKk/jLY=";
	
	XCTAssertTrue([expectedSig isEqualToString:signature], @"Invalid Signature");
}

- (void)testParametersInURLAndPost
{
	NSString *consumerKey = @"xvz1evFS4wEEPTGEFPHBog";
	NSString *consumerSecret = @"kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw";
	
	NSString *token = @"370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb";
	NSString *tokenSecret = @"LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE";
	
	DTOAuthClient *client = [[DTOAuthClient alloc] initWithConsumerKey:consumerKey
																		 consumerSecret:consumerSecret];
	[client _setToken:token
				  secret:tokenSecret];
	
	
	NSURL *URL = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json?include_entities=true"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	request.HTTPMethod = @"POST";
	NSString *body = @"status=Hello%20Ladies%20%2b%20Gentlemen%2c%20a%20signed%20OAuth%20request%21";
	request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
	
	NSString *authHeader = [client authenticationHeaderForRequest:request];
	XCTAssertNotNil(authHeader, @"Header is nil");
	
	XCTAssertTrue([authHeader hasPrefix:@"OAuth"], @"Wrong prefix");
	
	NSRange rangeOfSignature = [authHeader rangeOfString:@"tnnArxj06cWHq44gCs1OSKk/jLY="];
	XCTAssertNotEqual(rangeOfSignature.location, NSNotFound, @"Wrong signature");
	
	NSRange rangeOfURLParam = [authHeader rangeOfString:@"include_entities"];
	XCTAssertEqual(rangeOfURLParam.location, NSNotFound, @"URL param should not be present in OAuth header");
	
	NSRange rangeOfPostParam = [authHeader rangeOfString:@"status"];
	XCTAssertEqual(rangeOfURLParam.location, NSNotFound, @"Post param should not be present in OAuth header");

}

@end
