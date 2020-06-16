//
//  NSObject+XWKVO.m
//  XWInterviewDemos
//
//  Created by 邱学伟 on 2020/6/15.
//  Copyright © 2020 邱学伟. All rights reserved.
//

#import "NSObject+XWKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface XWKVOObservationInfo : NSObject
@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) XWObservingBlock block;
+ (instancetype)infoWithObserver:(NSObject *)observer key:(NSString *)key block:(XWObservingBlock)block;
@end

@implementation NSObject (XWKVO)
static NSString * const kXWKVOClassPrefix = @"kXWKVOClassPrefix_";
static void *kXWKVOAssociatedObserversKey = &kXWKVOAssociatedObserversKey;

- (void)xw_addObserver:(NSObject *)observer forKey:(NSString *)key block:(XWObservingBlock)block {
    SEL setterSelector = NSSelectorFromString(setterForKey(key));
    Method setterMethod = class_getInstanceMethod(self.class, setterSelector);
    if (!setterMethod) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have a setter for key %@", self, key];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    
    Class class = object_getClass(self);
    NSString *className = NSStringFromClass(class);
    if (![className hasPrefix:kXWKVOClassPrefix]) {
        class = [self makeKVOClassWithClassName:className];
        object_setClass(self, class);// 重置isa （此时当前类isa指向新创建的派生类）
    }
    
    if (![self hasSelector:setterSelector]) {
        // 新派生类无此属性的监听
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(class, setterSelector, (IMP)kvo_setter, types);
    }
    
    XWKVOObservationInfo *info = [XWKVOObservationInfo infoWithObserver:observer key:key block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self, kXWKVOAssociatedObserversKey);
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, kXWKVOAssociatedObserversKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
}

- (void)xw_removeObserver:(NSObject *)observer forKey:(NSString *)key {
    NSMutableArray *observers = objc_getAssociatedObject(self, kXWKVOAssociatedObserversKey);
    XWKVOObservationInfo *removeInfo;
    for (XWKVOObservationInfo *info in observers) {
        if (info.observer == observer && [info.key isEqualToString:key]) {
            removeInfo = info;
            break;
        }
    }
    if (removeInfo) {
        [observers removeObject:removeInfo];
    }
}

#pragma mark - OverWrite
static void kvo_setter(id self, SEL _cmd, id newValue) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);
    
    if (!getterName) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have setter %@", self, setterName];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superCls = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    void(*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superCls, _cmd, newValue);
    
    NSMutableArray <XWKVOObservationInfo *> *observers      = objc_getAssociatedObject(self, kXWKVOAssociatedObserversKey);
    NSMutableArray <XWKVOObservationInfo *> *removeInfos    = [[NSMutableArray alloc] initWithCapacity:observers.count];
    for (XWKVOObservationInfo *info in observers) {
        if (!info.observer) {
            [removeInfos addObject:info];
            continue;
        }
        if ([info.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                info.block(self, getterName, oldValue, newValue);
            });
        }
    }
    if (removeInfos.count > 0) {
        [observers removeObjectsInArray:removeInfos];
    }
}

- (Class)makeKVOClassWithClassName:(NSString *)className {
    NSString *kvoClassName = [kXWKVOClassPrefix stringByAppendingString:className];
    Class kvoClass = NSClassFromString(kvoClassName);
    if (kvoClass) {
        return kvoClass;
    }
    Class superclass = object_getClass(self);
    kvoClass = objc_allocateClassPair(superclass, kvoClassName.UTF8String, 0);
    
    Method superclassClassMethod = class_getInstanceMethod(superclass, @selector(class));
    const char *types = method_getTypeEncoding(superclassClassMethod);
    class_addMethod(kvoClass, @selector(class), (IMP)kvo_class, types);
    
    objc_registerClassPair(kvoClass);
    return kvoClass;
}

- (BOOL)hasSelector:(SEL)aSelector {
    Class class = object_getClass(self);
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(class, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (aSelector == thisSelector) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;
}

#pragma mark - Helpers
static NSString *getterForSetter(NSString *setter) {
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    return [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstLetter];
}

static NSString *setterForKey(NSString *key) {
    if (key.length <= 0) {
        return nil;
    }
    NSString *firstLetter = [[key substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [key substringFromIndex:1];
    return [NSString stringWithFormat:@"set%@%@:",firstLetter,remainingLetters];
}

static Class kvo_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}
@end

@implementation XWKVOObservationInfo
+ (instancetype)infoWithObserver:(NSObject *)observer key:(NSString *)key block:(XWObservingBlock)block {
    return [[XWKVOObservationInfo alloc] initWithObserver:observer key:key block:block];
}
- (instancetype)initWithObserver:(NSObject *)observer key:(NSString *)key block:(XWObservingBlock)block {
    if (self = [super init]) {
        self.observer = observer;
        self.key = key;
        self.block = block;
    }
    return self;
}
@end
