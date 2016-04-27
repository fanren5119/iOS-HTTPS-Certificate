//
//  ShenYun_Connection.h
//  ShenYunSample
//
//  Created by 王磊 on 16/4/26.
//  Copyright © 2016年 Summer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFSecurityPolicy.h"

typedef void (^CompleteBlock) (NSData *data, NSError *connectionError) ;

@interface ShenYun_Connection : NSObject

@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
@property (nonatomic, strong) NSURLCredential *credential;

- (id)initWithRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue;

- (void)AsynRequestWithCompleteBlock:(CompleteBlock)completeBlock;

@end
