//
//  PBURLProtocol.h
//  PBURLProtocol
//
//  Created by Bennett on 2016/12/12.
//  Copyright © 2016年 PB-Tech. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kPBURLProtocolIsHandle;

typedef BOOL(^PBURLProtocolInterceptRule)(NSURLRequest *request);
typedef NSURLRequest* (^PBURLProtocolRebuildRequest)(NSURLRequest *orignal);

@interface PBURLProtocol : NSURLProtocol

+ (void)setInterceptRule:(PBURLProtocolInterceptRule)interceptRule;
+ (void)setRebuildBlock:(PBURLProtocolRebuildRequest)rebuildBlock;


+ (void)enableScheme:(NSString*)scheme;
+ (void)disableScheme:(NSString*)scheme;

+ (void)start;
+ (void)stop;

@end
