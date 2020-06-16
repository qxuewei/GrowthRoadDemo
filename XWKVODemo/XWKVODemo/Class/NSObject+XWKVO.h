//
//  NSObject+XWKVO.h
//  XWInterviewDemos
//
//  Created by 邱学伟 on 2020/6/15.
//  Copyright © 2020 邱学伟. All rights reserved.
//  自定义KVO

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef void(^XWObservingBlock)(id obj, NSString *key, id oldValue, id newValue);
@interface NSObject (XWKVO)

/// 添加KVO监听
/// @param observer 监听者
/// @param key 属性
/// @param block 回调
- (void)xw_addObserver:(NSObject *)observer forKey:(NSString *)key block:(XWObservingBlock)block;

/// 移除KVO监听
/// @param observer 监听者
/// @param key 属性
- (void)xw_removeObserver:(NSObject *)observer forKey:(NSString *)key;

@end
NS_ASSUME_NONNULL_END
