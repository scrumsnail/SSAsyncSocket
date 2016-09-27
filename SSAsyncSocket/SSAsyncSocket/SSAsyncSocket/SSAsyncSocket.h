//
//  SSAsyncSocket.h
//  SSAsyncSocket
//
//  Created by allthings_LuYD on 16/9/26.
//  Copyright © 2016年 scrum_snail. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSAsyncSocket : NSObject
+ (id)sharedSocket;
- (void)startConnectSocket;
@end
