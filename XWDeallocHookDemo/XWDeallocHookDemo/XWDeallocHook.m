//
//  XWDeallocHook.m
//  XWKVODemo
//
//  Created by 邱学伟 on 2020/6/16.
//  Copyright © 2020 极客学伟科技有限公司. All rights reserved.
//

#import "XWDeallocHook.h"
#import <objc/runtime.h>

@interface XWDeallocHook ()
@property (copy, nonatomic) dispatch_block_t callback;
@end

@implementation XWDeallocHook
static void *kXWDeallocHookKey = &kXWDeallocHookKey;

+ (void)hookDeallocToObj:(id)obj callback:(dispatch_block_t)callback {
    XWDeallocHook *hook = [[XWDeallocHook alloc] initWithCallback:callback];
    objc_setAssociatedObject(obj, kXWDeallocHookKey, hook, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (instancetype)initWithCallback:(dispatch_block_t)callback {
    if (self = [super init]) {
        self.callback = callback;
    }
    return self;
}

- (void)dealloc {
    self.callback ? self.callback() : nil;
}

@end
