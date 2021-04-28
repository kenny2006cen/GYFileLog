//
//  GYRecordLog.h
//  GYLog
//
//  Created by jianglincen on 2021/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define PathComponent [[NSString stringWithUTF8String:__FILE__] lastPathComponent]

#define RegisteredLog(days) [[GYRecordLog shareInstance] registeredLog:PathComponent manyDay:days]

#define GYForceRecord(frmt,...) [GYRecordLog recordLogFromClass:PathComponent logMessage:[NSString stringWithFormat:frmt, ## __VA_ARGS__]]

@interface GYFileLog : NSObject

//初始化日志记录
+ (GYFileLog *)shareInstance;

//注册记录日志 days 以天为单位，默认是删除7天以前的日志 =>请使用宏定义方法执行
- (void)registeredLog:(NSString *)className
              manyDay:(NSInteger)days;

//获取记录日志目录
+ (NSString *)getRecordLogPath;

//记录日志 =>请使用宏定义方法执行
+ (void)recordLogFromClass:(NSString *)className
                logMessage:(NSString *)logStr;


@end

NS_ASSUME_NONNULL_END
