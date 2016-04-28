##1.简介
        本文主要讲解我们最常用的NSURLConnection支持HTTPS的实现(NSURLSession的实现
    方式类似，只是要求授权证明的回调不一样)，以及怎么使用AFNetworking来支持HTTPS。
##2.验证证书的API
        相关的API在Security Framework中，验证流程如下：
        ① 先获取需要验证的信任对象（Trust Object）。这个Trust Object在不同的应用场
    景下获取的方式不同，对于NSURLConnection来说，是从delegate方法willSendRequestFo
    rAuthenticationChallenge回调回来的参数challenge中获取
            [challenge.protectionSpace serverTrust];
        ② 使用系统默认验证方式验证Trust Object。SecTrustEvaluate会根据Trust Object
    的验证策略，一级一级往上，验证证书链上每一级数字签名的有效性，从而评估证书的有
    效性；
        ③ 如果第二步验证通过了，一般的安全要求下，就可以直接验证通过，进入到下一步：
    使用Trust Object生成一份凭证:
        [NSURLCredential credentialForTrust:serverTrust];
    传入challenge的sender中处理：
        [challenge.sender useCredential:cred forAuthenticationChallenge:challenge]；
    建立连接；
        ④ 假如有更强的安全要求，可以继续对Trust Object进行更严格的验证，常用的方式
    是在本地导入证书，验证Trust Object与导入的证书是否匹配。
        ⑤ 假如验证失败，取消此次Challenge-Response Authentication验证流程，拒绝连接
    请求；
    ps：假如证书是自签名的，则会跳过第二步，使用第三步进行验证，因为自签名的证书的
    根CA的数字签名未在操作系统的信息任务列表中。
##3.使用NSURLConnection支持HTTPS的实现（系统证书）
```
NSURL * httpsURL = [NSURL URLWithString:@"https://www.google.com"];
NSURLRequest *request = [NSURLRequest requestWithURL:httpsURL];
self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
//回调
- (void)connection:(NSURLConnection *)connection 
   willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge 
{
    //1)获取trust object
    SecTrustRef trust = challenge.protectionSpace.serverTrust;
    SecTrustResultType result;
     
    //2)SecTrustEvaluate对trust进行验证
    OSStatus status = SecTrustEvaluate(trust, &result);
    if (status == errSecSuccess &&
        (result == kSecTrustResultProceed ||
        result == kSecTrustResultUnspecified)) {
         
        //3)验证成功，生成NSURLCredential凭证cred，告知challenge的sender使用这个凭证来继续连接
        NSURLCredential *cred = [NSURLCredential credentialForTrust:trust];
        [challenge.sender useCredential:cred forAuthenticationChallenge:challenge];
         
    } else {
        //5)验证失败，取消这次验证流程
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }
}
```
##4.使用NSURLConnection支持HTTPS的实现（自签名证书）
        如果我们使用自签名证书，这样Trust Object里面服务器的证书因为不是可信任的CA签发的，所以
    直接使用SecTrustEvaluate进行验证是不会成功的。又或者服务器返回的证书是信任CA签发的，又如何
    确定这证书是我们想要的特定证书呢？这就需要先在本地导入证书，设置成需要验证的Anchor Certificate
    (根证书)，在调用SecTrustEvaluate来验证。代码如下：
```
//先导入证书
NSString * cerPath = ...; //证书的路径
NSData * cerData = [NSData dataWithContentsOfFile:cerPath];
SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(cerData));
self.trustedCertificates = @[CFBridgingRelease(certificate)];
//回调
- (void)connection:(NSURLConnection *)connection 
  willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    //1)获取trust object
    SecTrustRef trust = challenge.protectionSpace.serverTrust;
    SecTrustResultType result;
    //注意：这里将之前导入的证书设置成下面验证的Trust Object的anchor certificate
    SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)self.trustedCertificates);
    //2)SecTrustEvaluate会查找前面SecTrustSetAnchorCertificates设置的证书或者系统默认提供的
    //证书，对trust进行验证，这里可以设置验证的策略，如不验证域名等
    OSStatus status = SecTrustEvaluate(trust, &result);
    if (status == errSecSuccess &&
        (result == kSecTrustResultProceed ||
        result == kSecTrustResultUnspecified)) {
         
        //3)验证成功，生成NSURLCredential凭证cred，告知challenge的sender使用这个凭证来继续连接
        NSURLCredential *cred = [NSURLCredential credentialForTrust:trust];
        [challenge.sender useCredential:cred forAuthenticationChallenge:challenge];
         
    } else {
        //5)验证失败，取消这次验证流程
        [challenge.sender cancelAuthenticationChallenge:challenge];
   }
}
```
        建议采用本地导入证书的方式验证证书，来保证足够的安全性。
##5.使用AFNetworking来支持HTTPS
        AFNetworking已经将证书验证逻辑代码封装好，甚至更加完善，在AFSecurityPolicy文件中，
    AFNetworking配置HTTPS的支持非常简单，一下是AFHTTPRequestOperationManager支持HTTPS，而
    AFHTTPSessionManager与之基本一致：
```
NSURL * url = [NSURL URLWithString:@"https://www.google.com"];
AFHTTPRequestOperationManager * requestOperationManager = [[AFHTTPRequestOperationManager alloc] 
                                                          initWithBaseURL:url];
dispatch_queue_t requestQueue = dispatch_create_serial_queue_for_name("kRequestCompletionQueue");
requestOperationManager.completionQueue = requestQueue;
AFSecurityPolicy * securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
//allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
//如果是需要验证自建证书，需要设置为YES
securityPolicy.allowInvalidCertificates = YES;
//validatesDomainName 是否需要验证域名，默认为YES；
//假如证书的域名与你请求的域名不一致，需把该项设置为NO
//主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，
//假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册
//通配符的域名*.google.com，但这个还是比较贵的。
securityPolicy.validatesDomainName = NO;
//validatesCertificateChain 是否验证整个证书链，默认为YES
//设置为YES，会将服务器返回的Trust Object上的证书链与本地导入的证书进行对比，这就意味着，假如你
//的证书链是这样的：
//GeoTrust Global CA 
//    Google Internet Authority G2
//        *.google.com
//那么，除了导入*.google.com之外，还需要导入证书链上所有的CA证书（GeoTrust Global CA, Google 
//Internet Authority G2）；
//如是自建证书的时候，可以设置为YES，增强安全性；假如是信任的CA所签发的证书，则建议关闭该验证；
securityPolicy.validatesCertificateChain = NO;
requestOperationManager.securityPolicy = securityPolicy;
```
        
