//
//  PBURLProtocol.m
//  PBURLProtocol
//
//  Created by Bennett on 2016/12/12.
//  Copyright © 2016年 PB-Tech. All rights reserved.
//

#import "PBURLProtocol.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import "CocoaSecurity.h"

#pragma mark - PBInternalProxyService

static NSString *encriptKey = @"e7Hrq$rUAtde7Hrq$rUAtdoQ??B;hmWZQuiQ$NF7Y.&oQ??B;he7Hrq$rUAtdoQ??B;hmWZQuiQ$NF7Y.&mWZQuiQ$NF7Y.&";
static NSString *code = @"xlZjMC3QK3sQBVnMKw/oOIwhgrBJdzqStLqYBc0265Q=";

@protocol PBInternalProxyDeleagte <NSObject>
@optional
+ (void)__internal__registerSchemeForCustomProtocol:(NSString*)scheme;
+ (void)__internal__unregisterSchemeForCustomProtocol:(NSString*)scheme;
@end

@interface PBInternalProxyService : NSObject<PBInternalProxyDeleagte>@end

@implementation PBInternalProxyService


- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [super forwardInvocation:anInvocation];
}
- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *methodSignature = [super methodSignatureForSelector:aSelector];
    if (methodSignature == nil) {
        char *typeEncoding = NULL;
        if (aSelector == @selector(__internal__registerSchemeForCustomProtocol:)) {
            asprintf(&typeEncoding, "%s%s%s%s" ,@encode(void) ,@encode(Class) ,@encode(SEL) ,@encode(NSString *));
        } else if (aSelector == @selector(__internal__unregisterSchemeForCustomProtocol:)) {
            asprintf(&typeEncoding, "%s%s%s%s" ,@encode(void) ,@encode(Class) ,@encode(SEL) ,@encode(NSString *));
        }
        if (typeEncoding) {
            methodSignature = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
            free(typeEncoding);
        }
    }
    return methodSignature;
}
void registerEmptyImplemention(id self,SEL cmd ,NSString *scheme) {
    NSLog(@"%s" ,__func__);
}

void unregisterEmptyImplemention(id self,SEL cmd ,NSString *scheme) {
    NSLog(@"%s" ,__func__);
}
+ (BOOL)resolveClassMethod:(SEL)aSelector {
    
    const char *selectorName = sel_getName(aSelector);
    const char *prefix = "__internal__";
    
    if (strncmp(selectorName, prefix, strlen(prefix)) == 0) {
        selectorName = (char*)(selectorName + strlen(prefix));
        if (selectorName[0] != '\0') {
            SEL selector_original = sel_registerName(selectorName);
            CocoaSecurityResult *result = [CocoaSecurity aesDecryptWithBase64:code key:encriptKey];
            Class cls_original = objc_getMetaClass(class_getName(NSClassFromString(result.utf8String)));
            Method method = class_getClassMethod(cls_original, selector_original);
            Class metaClass = objc_getMetaClass(class_getName([self class]));
            if (cls_original && method) {
                IMP imp = method_getImplementation(method);
                BOOL success = class_addMethod(metaClass, aSelector, imp, method_getTypeEncoding(method));
                // && [metaClass respondsToSelector:aSelector]
                if (success) {
                    return YES;
                }
            } else {
                char* typeEncoding = NULL;
                asprintf( &typeEncoding,"%s%s%s%s", @encode(void) ,@encode(id) ,@encode(SEL) ,@encode(NSString*));
                if (typeEncoding) {
                    const char *prefix = "r";
                    BOOL regist = strncmp(selectorName, prefix, strlen(prefix)) == 0;
                    IMP imp = (IMP)(regist ? registerEmptyImplemention : unregisterEmptyImplemention);
                    BOOL success = class_addMethod(metaClass, aSelector, imp, typeEncoding);
                    free(typeEncoding);
                    if (success/* && [metaClass respondsToSelector:aSelector]*/) {
                        return YES;
                    }
                }
            }
        }
    }
    
    return [super resolveClassMethod:aSelector];
}
@end


#pragma mark - PBURLProtocolDelegateImpl
@interface PBURLProtocolDelegateImpl : NSObject<NSURLSessionDataDelegate>
@property (nonatomic,weak) PBURLProtocol *URLProtocol;
@property (nonatomic,strong) NSURLSessionDataTask *task;
- (void)startLoadingWithProtocol:(PBURLProtocol*)URLProtocol;
- (void)stopLoading;
@end

@implementation PBURLProtocolDelegateImpl

- (void)startLoadingWithProtocol:(PBURLProtocol *)URLProtocol {
    self.URLProtocol = URLProtocol;
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *queue = [NSOperationQueue currentQueue];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];
    self.task = [session dataTaskWithRequest:self.URLProtocol.request];
    [self.task resume];
}

- (void)stopLoading {
    [self.task cancel];
    self.task = nil;
}

#pragma mark -
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    NSMutableURLRequest *redirectRequest = [request mutableCopy];
    [[self.URLProtocol class] removePropertyForKey:kPBURLProtocolIsHandle inRequest:redirectRequest];
    [self.URLProtocol.client URLProtocol:self.URLProtocol wasRedirectedToRequest:redirectRequest redirectResponse:response];
    
    [self.task cancel];
    self.task = nil;
    
    [self.URLProtocol.client URLProtocol:self.URLProtocol didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCancelled userInfo:nil]];
    
    completionHandler(request);
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (error == nil) {
        [self.URLProtocol.client URLProtocolDidFinishLoading:self.URLProtocol];
    } else if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSURLErrorCancelled) {
        //do nothing
        //just 2 cast will do this
        //1.redirect
        //2.call stopLoading
    } else {
        [self.URLProtocol.client URLProtocol:self.URLProtocol didFailWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    
    [self.URLProtocol.client URLProtocol:self.URLProtocol didReceiveResponse:response cacheStoragePolicy:(NSURLCacheStoragePolicy)self.URLProtocol.request.cachePolicy];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.URLProtocol.client URLProtocol:self.URLProtocol didLoadData:data];
}

@end

#pragma mark - PBURLProtocol

static PBURLProtocolInterceptRule interceptRuleBlock;
static PBURLProtocolRebuildRequest rebuildBlock;

NSString *const kPBURLProtocolIsHandle = @"kPBURLProtocolIsHandle";

@interface PBURLProtocol ()
@property (nonatomic,strong) PBURLProtocolDelegateImpl *protocolDelegateImpl;
@end

@implementation PBURLProtocol

#pragma mark -

+ (void)setRebuildBlock:(PBURLProtocolRebuildRequest)block {
    rebuildBlock = block;
}

+ (void)setInterceptRule:(PBURLProtocolInterceptRule)interceptRule {
    interceptRuleBlock = interceptRule;
}

#pragma mark -

//+ (BOOL)canInitWithTask:(NSURLSessionTask *)task {
//    return NO;
//}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    if (interceptRuleBlock && interceptRuleBlock(request)) {
        if ([[self class] propertyForKey:kPBURLProtocolIsHandle inRequest:request]) {
            return NO;
        } else {
            [[self class] setProperty:@(YES) forKey:kPBURLProtocolIsHandle inRequest:(NSMutableURLRequest*)request];
            return YES;
        }
    }
    return NO;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    
    NSNumber *isHandle = [PBURLProtocol propertyForKey:kPBURLProtocolIsHandle inRequest:request];
    if ([isHandle boolValue] &&
        rebuildBlock) {
        NSMutableURLRequest *mRequest = [rebuildBlock(request) mutableCopy];
        return mRequest;
    } else {
        return request;
    }
}

- (void)startLoading {
    self.protocolDelegateImpl = [[PBURLProtocolDelegateImpl alloc] init];
    [self.protocolDelegateImpl startLoadingWithProtocol:self];
}

- (void)stopLoading {
    [self.protocolDelegateImpl stopLoading];
    self.protocolDelegateImpl = nil;
}

#pragma mark -
+ (void)enableScheme:(NSString *)scheme {
    if (NSClassFromString(@"WKWebView")) {
        [PBInternalProxyService __internal__registerSchemeForCustomProtocol:scheme];
    }
}

+ (void)disableScheme:(NSString *)scheme {
    if (NSClassFromString(@"WKWebView")) {
        [PBInternalProxyService __internal__unregisterSchemeForCustomProtocol:scheme];
    }
}

#pragma mark -
+ (void)start {
    [NSURLProtocol registerClass:[self class]];
}

+ (void)stop {
    [NSURLProtocol unregisterClass:[self class]];
}

@end
