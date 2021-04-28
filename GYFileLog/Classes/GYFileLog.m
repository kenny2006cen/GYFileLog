//
//  GYRecordLog.m
//  GYLog
//
//  Created by jianglincen on 2021/4/27.
//

#import "GYFileLog.h"

//默认保存7天
static NSInteger saveLogDay = 7;

@interface GYFileLog () {
    
    NSString * _appName;
    NSString * _appVersion;
    NSString * _bundleName;
    NSString * _deviceVersion;
    NSString * _logPath;
    dispatch_queue_t _loggerQueue;
    
    NSOperationQueue *_queue;

}
@end

@implementation GYFileLog

+(void)load{
    
    [[GYFileLog shareInstance]configData];
}

#pragma mark - 单例
+ (GYFileLog *)shareInstance
{
    static GYFileLog * manager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        manager = [[GYFileLog alloc] init];
        
        [manager configData];

    });
    return manager;
}

#pragma mark - method


/// 获取设备名称，版本，开启消息队列，创建默认文件夹
-(void)configData{
    
    _appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    _deviceVersion = [[UIDevice currentDevice] systemVersion];
    
    _logPath = [self appLogPathWithName:_appName];
    
    _queue =[NSOperationQueue new];
    _queue.maxConcurrentOperationCount =1;
    
    BOOL isSuccess = [self createDirectoryWithPath:_logPath error:nil];
    
    if (!isSuccess) {
        NSLog(@"log create directory failed\n");
        return;
    }
    
}

-(NSString*)appLogPathWithName:(NSString*)name{
 
    NSString* documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    NSString * logPath = [documentPath stringByAppendingPathComponent:@"GYLog"];

    return logPath;
    
    
}


-(BOOL)createDirectoryWithPath:(NSString *)path
                         error:(NSError **)error{

    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (isDirExist && isDir)return YES;
    
    NSURL * fileUrl = [NSURL URLWithString:path];
    NSArray * pathComponents = fileUrl.pathComponents;
    if (pathComponents.count == 0)return NO;
    
    BOOL isSuccess = [fileManager createDirectoryAtPath:path
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:error];
    
    return isSuccess;
}


/// 根据时间移除文件
/// @param floderPath 文件路径
/// @param longDay 天数
- (void)removeFileWithPath:(NSString *)floderPath
                   longDay:(NSInteger)longDay{
    
   // NSFileManager  * fileManager = [NSFileManager  defaultManager];
    
    

}

+ (BOOL)isRemoveDirectoryWithDateStr:(NSString *)dateStr
                             longDay:(NSInteger)longDay{
    
  
    return NO;
}

/// 返回2021-01-02 22:22:21格式
+ (NSString *)currentTimeString
{
   static NSDateFormatter *timeformatter = nil;
    
    if (!timeformatter) {
        timeformatter = [[NSDateFormatter alloc] init];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [timeformatter setLocale:locale];
        timeformatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }

    NSString * currentDateStr = [timeformatter stringFromDate:[self currentDate]];
   
    return currentDateStr;
}


/// 返回2021-01-02 格式
+ (NSString *)currentDayString {
    
    static NSDateFormatter *dayformatter = nil;
     
     if (!dayformatter) {
         dayformatter = [[NSDateFormatter alloc] init];
         NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
         [dayformatter setLocale:locale];
         [dayformatter setDateFormat:@"yyyy-MM-dd"];

     }
    NSString * currentDateStr = [dayformatter stringFromDate:[self currentDate]];
    
    return currentDateStr;
}


+ (NSDate *)currentDate
{
    NSDate  * currentDate = [NSDate date];
    NSCalendar * currentCalendar = [NSCalendar currentCalendar];
    if (currentCalendar.calendarIdentifier == NSCalendarIdentifierGregorian) {
        return currentDate;
    }
    NSCalendar * calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]; //只考虑公历
    NSCalendarUnit unit = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitWeekday|
    NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitNanosecond;
    NSDateComponents * componenets = [calendar components:unit fromDate:currentDate];
    NSDate * newDate = [calendar dateFromComponents:componenets];
    return newDate ? : currentDate;
}


- (void)registeredLog:(NSString *)className
              manyDay:(NSInteger)days
{
    
    @synchronized (className) {
        
    if (days <= 0) days = 7;
    
    BOOL isCantains = NO;

    NSString * classStr = @"";
    if (className.length > 0) {
        NSArray * classArray = [className componentsSeparatedByString:@"."];
        classStr = [classArray firstObject];
    }
    NSString * bundleStr = [self getCantainBundle:classStr isCantains:&isCantains];
    if (!isCantains) {
        NSLog(@"%@ project does not contain the '%@' module and cannot be logged\n",_appName,classStr);
        return;
    }
    NSBundle * bundle = classStr.length > 0 ? [NSBundle bundleForClass:NSClassFromString(classStr)] : [NSBundle mainBundle];
    
    NSDictionary * infoDictionary = [bundle infoDictionary];
    NSString * bundle_name = [infoDictionary objectForKey:@"CFBundleName"];
    NSString * logPath = [_logPath stringByAppendingPathComponent:bundle_name];
    
    BOOL isSuccess = [self createDirectoryWithPath:logPath error:nil];
    if (!isSuccess) {
        NSLog(@"ido log create directory failed\n");
        return;
    }
    
    [self removeFileWithPath:logPath longDay:days];
    NSString * str = [self stringByAppendingLogStr:bundleStr];
    
        [GYFileLog writeDefaultFolderLog:str];
   // [GYRecordLog writeRecordLog:str folderName:_appName];
        
    }
    
}

- (NSString *)getCantainBundle:(NSString *)className
                    isCantains:(BOOL*)isCantains
{
    NSString * bundleStr = @"";
    int index = 1;
    BOOL cantains = NO;
    NSBundle * currentBundle = [NSBundle bundleForClass:NSClassFromString(className)];
    NSString * currentName = [[currentBundle infoDictionary] objectForKey:@"CFBundleName"];
    for (NSBundle * bundle in [NSBundle allFrameworks]) {
        if ([bundle.bundlePath rangeOfString:@"/var/containers/Bundle/Application"].location != NSNotFound) {
            NSString * bundleName = [[bundle infoDictionary] objectForKey:@"CFBundleName"];
            NSString * bundleVersion = [[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            bundleStr = [bundleStr stringByAppendingFormat:@"framework%d:%@ version:%@\n",index,bundleName,bundleVersion];
            index ++;
            if ([bundleName isEqualToString:currentName]) {
                cantains = YES;
                
                break;
            }
        }
    }
    if (!cantains) {
        NSBundle * mainBundle = [NSBundle mainBundle];
        NSString * mainBundleName = [[mainBundle infoDictionary] objectForKey:@"CFBundleName"];
        if ([mainBundleName isEqualToString:currentName]) {
            cantains = YES;
            
        }
    }
    if (isCantains) {
        *isCantains = cantains;
    }
    return bundleStr;
}

- (NSString *)stringByAppendingLogStr:(NSString *)bundleStr
{
    NSString * appName    = _appName?:@"";
    NSString * appVersion = _appVersion?:@"";

    NSString * deviceVersion = _deviceVersion?:@"";
    NSString * lineStr  = @"=========================================";
  
    NSString * logStr1  = [NSString stringWithFormat:@"appName:%@\nappVersion:%@\nsystemVersion:%@",appName,appVersion,deviceVersion];
  
    NSString * logStr2 = [NSString stringWithFormat:@"%@\n%@\n%@\n",lineStr,logStr1,lineStr];
    return logStr2;
}

+ (void)recordLogFromClass:(NSString *)className
                logMessage:(NSString *)logStr
{
    NSString * classStr = @"";
    if (className.length > 0) {
        NSArray * classArray = [className componentsSeparatedByString:@"."];
        classStr = [classArray firstObject];
    }
    NSBundle * bundle = classStr.length > 0 ? [NSBundle bundleForClass:NSClassFromString(classStr)] : [NSBundle mainBundle];
    
    NSDictionary * infoDictionary = [bundle infoDictionary];
    NSString * time = [GYFileLog currentTimeString];
    NSString * bundle_version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString * bundle_name    = [infoDictionary objectForKey:@"CFBundleName"];
    NSString * headStr = [NSString stringWithFormat:@"[%@][%@][%@]",time,bundle_name,bundle_version];
    
    NSString * str = [NSString stringWithFormat:@"%@ %@\n\n",headStr,logStr];
    
     //   [self writeRecordLog:str folderName:[GYRecordLog shareInstance]->_appName];
    
    [self writeDefaultFolderLog:str];
}

+ (void)writeDefaultFolderLog:(NSString *)logStr
           
{

    NSBlockOperation * op =[NSBlockOperation blockOperationWithBlock:^{
        
        @autoreleasepool {
           
            NSString * logPath = [GYFileLog shareInstance]->_logPath;
            
            NSFileManager * fileManager = [NSFileManager defaultManager];
            BOOL isDir = NO;
            BOOL isDirExist = [fileManager fileExistsAtPath:logPath isDirectory:&isDir];
                    if (!isDir || !isDirExist) {
                        NSLog(@"please register the log to create a directory first");
                        return;
                    }
            
            NSString * fileName = [NSString stringWithFormat:@"%@.log",[GYFileLog currentDayString]];
          
#pragma mark - 如果不强制锁住文件名称，日志文件名称在子线程和主线程不断切换过程中，会变化成2021-04-06 17/15/53.326.log的格式 mark by jlc

            @synchronized (fileName) {
                                
                NSString * filePath = [logPath stringByAppendingPathComponent:fileName];
                
                @try {
                    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                        NSString * firstLog = @"";
                        [firstLog writeToFile:filePath
                                   atomically:YES
                                     encoding:NSUTF8StringEncoding
                                        error:nil];
                    }
                    NSFileHandle * fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
                                if (!fileHandle) {
                                    NSLog(@"file handle is null");
                                    return;
                                }
                    [fileHandle seekToEndOfFile];
                    NSData * buffer = [logStr dataUsingEncoding:NSUTF8StringEncoding];
                    [fileHandle writeData:buffer];
                    [fileHandle closeFile];
                } @catch (NSException *exception) {
                }
                
            }
            
           
        }
        
    }];
    
    op.queuePriority = NSOperationQueuePriorityNormal;
    op.qualityOfService = NSQualityOfServiceUtility;

    [[GYFileLog shareInstance]->_queue addOperations:@[op] waitUntilFinished:YES];

}


+ (void)writeRecordLog:(NSString *)logStr
            folderName:(NSString *)folderName
{
//    if (![[GYRecordLog shareInstance]->_bundleNAmes containsObject:folderName]) {
//        NSLog(@"please registered %@ log first",folderName);
//        return;
//    }
    
    NSBlockOperation * op =[NSBlockOperation blockOperationWithBlock:^{
        
        @autoreleasepool {
           
            NSString * logPath = [GYFileLog shareInstance]->_logPath;
            logPath = [logPath stringByAppendingPathComponent:folderName];
            
            NSFileManager * fileManager = [NSFileManager defaultManager];
            BOOL isDir = NO;
            BOOL isDirExist = [fileManager fileExistsAtPath:logPath isDirectory:&isDir];
                    if (!isDir || !isDirExist) {
                        NSLog(@"please register the log to create a directory first");
                        return;
                    }
            
            NSString * fileName = [NSString stringWithFormat:@"%@.log",[GYFileLog currentDayString]];
          
#pragma mark - 如果不强制锁住文件名称，日志文件名称在子线程和主线程不断切换过程中，会变化成2021-04-06 17/15/53.326.log的格式 mark by jlc

            @synchronized (fileName) {
                
                //NSLog(@"fileName=%@",fileName);
                
                NSString * filePath = [logPath stringByAppendingPathComponent:fileName];
                
                @try {
                    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                        NSString * firstLog = @"";
                        [firstLog writeToFile:filePath
                                   atomically:YES
                                     encoding:NSUTF8StringEncoding
                                        error:nil];
                    }
                    NSFileHandle * fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
                                if (!fileHandle) {
                                    NSLog(@"file handle is null");
                                    return;
                                }
                    [fileHandle seekToEndOfFile];
                    NSData * buffer = [logStr dataUsingEncoding:NSUTF8StringEncoding];
                    [fileHandle writeData:buffer];
                    [fileHandle closeFile];
                } @catch (NSException *exception) {
                }
                
            }
            
           
        }
        
    }];
    
    op.queuePriority = NSOperationQueuePriorityNormal;
    op.qualityOfService = NSQualityOfServiceUtility;

    [[GYFileLog shareInstance]->_queue addOperations:@[op] waitUntilFinished:YES];

}

+ (NSString *)getRecordLogPath{
    
    return [GYFileLog shareInstance]->_logPath;
    
}


@end
