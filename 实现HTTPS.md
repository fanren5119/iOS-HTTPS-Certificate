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
    的验证策略，以及以
