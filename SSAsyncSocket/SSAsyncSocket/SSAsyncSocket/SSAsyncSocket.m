//
//  SSAsyncSocket.m
//  SSAsyncSocket
//
//  Created by allthings_LuYD on 16/9/26.
//  Copyright © 2016年 scrum_snail. All rights reserved.
//

#import "SSAsyncSocket.h"
#import "GCDAsyncSocket.h"

static NSString *HOST = @"61.147.117.163";
static UInt16 PORT = 8881;
#define WRITE_LOGIN_TAG 101
#define READ_LOGIN_TAG  102
#define WRITE_TEST_SERVER_TAG 103
#define READ_TEST_SERVER_TAG 104

struct TestSrvData2 {
    char head[4];  // 31 30 31 30
    int length;      // 04 00 00 00
    unsigned short m_nType; // 05 09
    char  m_nlndex; //00
    char m_cOperator; //00
};

struct DataHead {
    char str[4]; // 32 30 31 30
    int length; //表示该字段之后的整个包体的长度
    unsigned short m_nTypr;
    char m_nlndex;
};

struct loginPack {
    char head[4];           //里面放"ZJHR"			4个字节  5a 4a 48 52
    int  length;           //后面数据的长度（包的长度减去8）			4个字节    94 00 00 00
    unsigned short 		m_nType;	     //请求类型						2个字节   02 01
    char				m_nIndex;     	 //请求索引，与请求数据包一致   1个字节  00
    char				m_No;            //暂时不用 					1个字节 00
    int                 m_lKey;		 	 //一级标识  					4个字节 03 00 00 00
    short				m_cCodeType;	 //证券类型 					2个字节 00  00
    char				m_cCode[6];		 //证券代码                     6个字节 00 00 00 00 00 00
    short     			m_nSize;         //请求证券总数                 2个字节 00 00
    unsigned short		m_nOption;       //为了4字节对齐而添加的字段    2个字节  00 00
    char			m_szUser[64];	     //用户名     64个字节  67 75 65 73 74 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
    char			m_szPWD[64];	//密码            64个字节 31 32 33 34 35 36 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
};

typedef struct TestSrvData2 TestSrv;
typedef struct DataHead DataHead;
typedef struct loginPack LoginPack;
@interface SSAsyncSocket ()<GCDAsyncSocketDelegate>
@property (nonatomic,strong) GCDAsyncSocket *ss_asyncSocket;
@property(strong,nonatomic)NSMutableArray *clientSocket;
@end

@implementation SSAsyncSocket

-(NSMutableArray *)clientSocket{
    if (_clientSocket == nil) {
        _clientSocket = [NSMutableArray array];
    }
    return _clientSocket;
}

+ (id)sharedSocket{
    static SSAsyncSocket *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

/*
 全局队列（代理的方法是在子线程被调用）
 
 主队列 （代理的方法会在主线程被调用）
 dispatch_get_main_queue()
 代理里的动作是耗时的动作，要在子线程中操作
 代理里的动作不是耗时的动作，就可以在主线程调用
 */
- (instancetype)init{
    if (self = [super init]) {
        _ss_asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    return self;
}

- (void)startConnectSocket{
    if (_ss_asyncSocket.isConnected) {
        return;
    }
    NSError *error = nil;
    [_ss_asyncSocket connectToHost:HOST onPort:PORT error:&error];
    if (error) {
        NSLog(@"链接失败");
    }else{
        NSLog(@"链接成功");
    }
}

- (void)login{
    LoginPack pack;

    const char head[4] = {'Z','J','H','R'};
    //通过变量的内存地址改变变量的值
    memcpy(pack.head, head, sizeof(head));
    pack.length = 0x94;

    const char nType[2] = {0x2,0x1};
    memcpy(&pack.m_nType, nType, sizeof(nType));

    pack.m_nIndex = 0;
    pack.m_No = 0;

    const char key[4] = {0x3,0,0,0};
    memcpy(&pack.m_lKey, key, sizeof(key));

    pack.m_cCodeType = 0;

    //将s所指向的某一块内存中的每一个字节的内容全部置为0
    memset(pack.m_cCode, 0, sizeof(pack.m_cCode));

    pack.m_nSize = 0;
    pack.m_nOption = 0;

    memset(pack.m_szUser, 0, sizeof(pack.m_szUser));

    //用户名
    NSString *user = @"guest";
    const void*user_data = [[user dataUsingEncoding:NSASCIIStringEncoding] bytes];
    memcpy(pack.m_szUser, user_data, sizeof(user_data));

    //密码
    NSString *pwd = @"123456";
    const void *pwd_data = [[pwd dataUsingEncoding:NSASCIIStringEncoding] bytes];
    memset(pack.m_szPWD, 0, sizeof(pack.m_szPWD));
    memcpy(pack.m_szPWD, pwd_data, sizeof(pwd_data));

    NSData *loginData = [[NSData alloc] initWithBytes:&pack length:sizeof(pack)];
    [_ss_asyncSocket writeData:loginData withTimeout:10 tag:WRITE_LOGIN_TAG];
}

- (void)testServer{
    TestSrv testSrv;
    memset(&testSrv, 0, sizeof(testSrv));

    NSString *head = @"ZJHR";
    const void *headData = [[head dataUsingEncoding:NSASCIIStringEncoding] bytes];
    memcpy(testSrv.head, headData, sizeof(testSrv.head));

    testSrv.length = sizeof(TestSrv) - 8;

    const char m_nType[2] = {0x5,0x9};
    memcpy(&testSrv.m_nType, m_nType, sizeof(testSrv.m_nType));

    testSrv.m_nlndex = 0;
    testSrv.m_cOperator = 0;

    NSData *data = [[NSData alloc] initWithBytes:&testSrv length:sizeof(testSrv)];
    NSLog(@"-----------------%@",data);

    [_ss_asyncSocket writeData:data withTimeout:10 tag:WRITE_TEST_SERVER_TAG];
}

#pragma mark - AsyncSocketDelegate-
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"sock----%@--host---%@--port--%d",sock,host,port);
    [self login];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"socket---%@--,tag---%ld",sock,tag);
    if (tag == WRITE_TEST_SERVER_TAG) {
        [sock readDataWithTimeout:10 tag:READ_TEST_SERVER_TAG];
    }else if (tag == WRITE_LOGIN_TAG){
        [sock readDataWithTimeout:10 tag:READ_LOGIN_TAG];
    }
}
/**
 * 服务端监听到有客户端接收会调用这个代理方法
 * sock            服务端
 * newSocket   客户端
**/
//- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
//    NSLog(@"服务端 %@",sock);
//    NSLog(@"客户端 %@",newSocket);
//    [self.clientSocket addObject:newSocket];
//    [newSocket readDataWithTimeout:-1 tag:100];
//}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@",dataStr);
    if (tag == READ_LOGIN_TAG) {
        DataHead head;
        memset(&head, 0, sizeof(head));

        //登录头
        [data getBytes:head.str length:sizeof(head.str)];
        [data getBytes:&head.length range:NSMakeRange(4, 4)];
        [data getBytes:&head.m_nTypr range:NSMakeRange(6, 2)];
        [data getBytes:&head.m_nlndex range:NSMakeRange(7, 1)];

        NSLog(@"head.str:%c%c%c%c",head.str[0],head.str[1],head.str[2],head.str[3]);
        NSLog(@"head.leng:%d",head.length);
        NSLog(@"head.m_nType:%d",head.m_nTypr);
        NSLog(@"head.m_nIndex:%d",head.m_nlndex);

        //登录体
        int contentSize = head.length - 11;
        void *content = malloc(contentSize);
        memset(content, 0, contentSize);
        [data getBytes:content range:NSMakeRange(11, contentSize)];
        NSLog(@"登录体内容长度%d",contentSize);
        free(content);

        //解析完发送心跳包
        [self testServer];

    }else if (tag == READ_TEST_SERVER_TAG){
        //心跳数据解析方案
        NSLog(@"持续发送心跳包中");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //解析完发送心跳包
            [self testServer];
        });
    }
}
@end
