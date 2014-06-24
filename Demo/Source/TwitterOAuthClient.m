//
//  TwitterOAuthClient.m
//  OAuthTest
//
//  Created by Oliver Drobnik on 6/23/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "TwitterOAuthClient.h"

@implementation TwitterOAuthClient

#pragma mark - OAuth URLs

- (NSURL *)requestTokenURL
{
	return [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
}

- (NSURL *)userAuthorizeURL
{
	return [NSURL URLWithString:@"https://api.twitter.com/oauth/authorize"];
}

- (NSURL *)accessTokenURL
{
	return [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
}

@end
