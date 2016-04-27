//
//  ViewController.m
//  HttpsTest
//
//  Created by 王磊 on 16/4/27.
//  Copyright © 2016年 wanglei. All rights reserved.
//

#import "ViewController.h"
#import "ShenYun_Connection.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *urlString = @"https://10.36.40.202/api/server";
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"GET";
    NSString *appKey = @"8aa4a89a53cb49b20153cb63c0740003";
    [request addValue:appKey forHTTPHeaderField:@"appKey"];
    
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    [request addValue:identifier forHTTPHeaderField:@"appPkgName"];
    
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    securityPolicy.allowInvalidCertificates = YES;
    securityPolicy.validatesDomainName = NO;
    securityPolicy.validatesCertificateChain = YES;
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    ShenYun_Connection *connection = [[ShenYun_Connection alloc] initWithRequest:request queue:queue];
    connection.securityPolicy = securityPolicy;
    [connection AsynRequestWithCompleteBlock:^(NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"error = %@", connectionError);
        } else {
            NSError *error = nil;
            id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"string = %@", string);
            if (error) {
                NSLog(@"error = %@", error);
            } else {
                NSLog(@"response = %@", responseObject);
            }
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
