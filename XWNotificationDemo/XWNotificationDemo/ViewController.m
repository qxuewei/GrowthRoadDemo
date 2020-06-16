//
//  ViewController.m
//  XWNotificationDemo
//
//  Created by 邱学伟 on 2020/1/8.
//  Copyright © 2020 邱学伟. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

static NSString * const kChangeImageFrameNotiName = @"kChangeImageFrameNotiName";

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeImageFrame) name:kChangeImageFrameNotiName object:nil];
}

- (IBAction)testClick:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kChangeImageFrameNotiName object:nil];
    });
}

- (void)changeImageFrame
{
    /// 通知在哪个线程post 则在哪个线程接收！
    NSLog(@"Thread Info: %@", [NSThread currentThread]);
    self.imageView.frame = CGRectMake(0, 100, 300, 100);
}

@end
