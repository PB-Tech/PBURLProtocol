# PBURLProtocol

This is a iOS network intercepter ,you can you this code mocking you network data ,inclue native code request and webView(WKWebView/UIWebView) request.

## CocoaPods

```
pod 'PBURLProtocol'
```

##Usage

It's easy to use.

```
[PBURLProtocol setInterceptRule:^BOOL(NSURLRequest *request) {
    //set up which requet will be block
    return YES;
}];

[PBURLProtocol setRebuildBlock:^NSURLRequest *(NSURLRequest *orignal) {
    //rebuild the request
    NSMutableURLRequest *req = orignal.mutableCopy;
    req.URL = [NSURL URLWithString:@"https://www.google.com"];
    return req;
}];
//custom which scheme will be intercept(just aviable from ios 9.0)
[PBURLProtocol enableScheme:@"http"];
[PBURLProtocol start];
```