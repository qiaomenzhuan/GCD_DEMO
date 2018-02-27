//
//  ViewController.m
//  GCDTest
//
//  Created by 杨磊 on 2018/2/26.
//  Copyright © 2018年 csda_Chinadance. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
/**
 区别          并发队列                     串行队列                      主队列
 同步(sync)    没有开启新线程，串行执行任务     没有开启新线程，串行执行任务      没有开启新线程，串行执行任务
 异步(async)   有开启新线程，并发执行任务      有开启新线程(1条)，串行执行任务    没有开启新线程，串行执行任务
 
 所以一共有六种组合方式
 
 这六种方式 只有异步+并发队列会并发执行任务 并开启多条线程
 这六种方式 异步+并发队列 异步+串行队列 这两种会开启新线程
 
 异步不会阻塞主线程
 
 这两个是并发队列 global是系统创建的全局并发队列 用哪个都可以
 dispatch_queue_t queue = dispatch_queue_create("orun_GCD", DISPATCH_QUEUE_CONCURRENT);
 dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
 
 这个是串行队列 区别就是参数DISPATCH_QUEUE_SERIAL
 dispatch_queue_t queue = dispatch_queue_create("orun_GCD", DISPATCH_QUEUE_SERIAL);

 
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    [self gcd_test];
//    [self sync_concurrent];
//    [self sync_serial];
//    [self sync_main];
//    [self async_concurrent];
//    [self async_serial];
//    [self async_main];
    
//        [NSThread detachNewThreadSelector:@selector(async_main) toTarget:self withObject:nil];

}

- (void)gcd_test
{
//    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("ddd", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        sleep(5);
        NSLog(@"任务一执行完毕 %@",[NSThread currentThread]);
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        sleep(12);
        NSLog(@"任务二执行完毕 %@",[NSThread currentThread]);
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"全部执行完了%@",[NSThread currentThread]);
    });

    dispatch_async(queue, ^{
        NSLog(@"大大%@",[NSThread currentThread]);
        dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
        NSLog(@"超时了%@",[NSThread currentThread]);
    });
    NSLog(@"多喝水多喝点水%@",[NSThread currentThread]);
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"sdffdsfdsfs");
    });
    
    NSLog(@"ewrewrew");
}

#pragma mark - 同步+并发
- (void)sync_concurrent
{
    NSLog(@"sync_concurrent----%@",[NSThread currentThread]);
    NSLog(@"sync_concurrent----begin");
    dispatch_queue_t queue = dispatch_queue_create("orun_GCD", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue2 = dispatch_get_global_queue(0, 0);
    dispatch_sync(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"sync_concurrent任务一 ----%d %@",i,[NSThread currentThread]);
        }
        dispatch_async(queue2, ^{
            for (int i = 0; i < 2; i++)
            {
                [NSThread sleepForTimeInterval:3];
                NSLog(@"sync_concurrent任务啥 ----%d %@",i,[NSThread currentThread]);
            }
        });
    });
    
    dispatch_sync(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:1];
            NSLog(@"sync_concurrent任务二 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    NSLog(@"sync_concurrent----end");
}

#pragma mark - 同步+串行
- (void)sync_serial
{
    NSLog(@"sync_serial----%@",[NSThread currentThread]);
    NSLog(@"sync_serial----begin");
    dispatch_queue_t queue = dispatch_queue_create("orun_GCD", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"sync_serial任务一 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    dispatch_sync(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:3];
            NSLog(@"sync_serial任务二 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    NSLog(@"sync_serial----end");
}

#pragma mark - 同步+主队列
- (void)sync_main
{
    /**
     1、在主线程中使用 同步+主队列 任务不会执行 并崩溃
     这是因为我们在主线程中执行sync_main方法，相当于把sync_main任务放到了主线程的队列中。而同步执行会等待当前队列中的任务执行完毕，才会接着执行。那么当我们把任务1追加到主队列中，任务1就在等待主线程处理完sync_main任务。而sync_main任务需要等待任务1执行完毕，才能接着执行。
     
     那么，现在的情况就是syncMain任务和任务1都在等对方执行完毕。这样大家互相等待，所以就卡住了，所以我们的任务执行不了，而且sync_main---end也没有打印。
     2、当不在子线程中使用 同步+主队列时 不会开启新线程 任务一个接一个执行
     使用 NSThread 的 detachNewThreadSelector 方法会创建线程，并自动启动线程执行
     selector 任务
     [NSThread detachNewThreadSelector:@selector(sync_main) toTarget:self withObject:nil];
     */
    NSLog(@"sync_main----%@",[NSThread currentThread]);
    NSLog(@"sync_main----begin");
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_sync(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"sync_main任务一 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    dispatch_sync(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:3];
            NSLog(@"sync_main任务二 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    NSLog(@"sync_main----end");
}

#pragma mark - 异步+并发队列
- (void)async_concurrent
{//六中组合方式唯一一个并发执行任务 两个任务开启了两条新线程
    NSLog(@"async_concurrent----%@",[NSThread currentThread]);
    NSLog(@"async_concurrent----begin");
    dispatch_queue_t queue = dispatch_queue_create("Orun_GCD", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"async_concurrent任务一 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    dispatch_async(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:3];
            NSLog(@"async_concurrent任务二 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    NSLog(@"async_concurrent----end");
}

#pragma mark - 异步+串行队列
- (void)async_serial
{//开辟了一条新线程
    NSLog(@"async_serial----%@",[NSThread currentThread]);
    NSLog(@"async_serial----begin");
    dispatch_queue_t queue = dispatch_queue_create("Orun_GCD", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"async_serial任务一 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    dispatch_async(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:3];
            NSLog(@"async_serial任务二 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    NSLog(@"async_serial----end");
}

#pragma mark - 异步+主线程
- (void)async_main
{//虽然是异步 但是不开辟新线程 在当前线程执行
    NSLog(@"async_main----%@",[NSThread currentThread]);
    NSLog(@"async_main----begin");
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_async(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"async_main任务一 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    dispatch_async(queue, ^{
        for (int i = 0; i < 2; i++)
        {
            [NSThread sleepForTimeInterval:3];
            NSLog(@"async_main任务二 ----%d %@",i,[NSThread currentThread]);
        }
    });
    
    NSLog(@"async_main----end");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
