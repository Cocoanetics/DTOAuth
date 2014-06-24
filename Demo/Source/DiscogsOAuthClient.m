//
//  DiscogsOAuthClient.m
//  DTOAuth
//
//  Created by Oliver Drobnik on 6/23/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DiscogsOAuthClient.h"

@implementation DiscogsOAuthClient

#pragma mark - OAuth URLs

- (NSURL *)requestTokenURL
{
	return [NSURL URLWithString:@"http://api.discogs.com/oauth/request_token"];
}

- (NSURL *)userAuthorizeURL
{
	return [NSURL URLWithString:@"http://www.discogs.com/oauth/authorize"];;
}

- (NSURL *)accessTokenURL
{
	return [NSURL URLWithString:@"http://api.discogs.com/oauth/access_token"];
}

@end
