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
