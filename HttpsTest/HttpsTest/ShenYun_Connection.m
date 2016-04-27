//
//  ShenYun_Connection.m
//  ShenYunSample
//
//  Created by 王磊 on 16/4/26.
//  Copyright © 2016年 Summer. All rights reserved.
//

#import "ShenYun_Connection.h"

@interface ShenYun_Connection () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection   *connection;
@property (nonatomic, strong) CompleteBlock     completeBlock;

@end

@implementation ShenYun_Connection

- (id)initWithRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue
{
    self = [super init];
    if (self) {
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        [self.connection setDelegateQueue:queue];
    }
    return self;
}

- (void)AsynRequestWithCompleteBlock:(CompleteBlock)completeBlock;
{
    self.completeBlock = completeBlock;
    [self.connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (self.completeBlock) {
        self.completeBlock(data, nil);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.completeBlock) {
        self.completeBlock(nil, error);
    }
}

- (void)connection:(NSURLConnection *)connection
willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        } else {
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    } else {
        if ([challenge previousFailureCount] == 0) {
            if (self.credential) {
                [[challenge sender] useCredential:self.credential forAuthenticationChallenge:challenge];
            } else {
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        } else {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

@end
