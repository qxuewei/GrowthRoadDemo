//
//  XWDeallocHook.h
//  XWKVODemo
//
//  Created by 邱学伟 on 2020/6/16.
//  Copyright © 2020 极客学伟科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XWDeallocHook : NSObject

/// Hook 对象的
/// @param obj <#obj description#>
/// @param callback <#callback description#>
+ (void)hookDeallocToObj:(id)obj callback:(dispatch_block_t)callback;
@end

NS_ASSUME_NONNULL_END
