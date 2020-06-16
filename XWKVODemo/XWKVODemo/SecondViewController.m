//
//  SecondViewController.m
//  XWKVODemo
//
//  Created by 邱学伟 on 2020/6/16.
//  Copyright © 2020 极客学伟科技有限公司. All rights reserved.
//

#import "SecondViewController.h"
#import "Person.h"
#import "NSObject+XWKVO.h"

@interface SecondViewController ()
@property (nonatomic, strong) Person *person;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addKVO];
}

- (void)dealloc {
    NSLog(@"🌹%s",__func__);
}

- (IBAction)changeClick:(id)sender {
    self.person.age += 1;
    self.person.name = [NSString stringWithFormat:@"name_%u",arc4random_uniform(100)];
}

- (void)addKVO {
    __weak typeof(self) ws = self;
    [self.person xw_addObserver:self forKey:@"name" block:^(id  _Nonnull obj, NSString * _Nonnull key, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"obj:%@ -- key:%@ -- oldValue:%@ -- newValue:%@ -- %@",obj,key,oldValue,newValue,ws);
    }];
}

- (Person *)person {
    if(!_person){
        _person = [[Person alloc] init];
    }
    return _person;
}

@end
