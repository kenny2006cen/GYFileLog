//
//  GYLog.h
//  GYLog
//
//  Created by jianglincen on 2021/4/27.
//

#ifndef GYLog_h
#define GYLog_h

#import <GYLog/GYRecordLog.h>
#import <GYLog/GYCrashLog.h>

#if defined(DEBUG) ||defined(_DEBUG)

#else

#define NSLog(...)
#endif


#endif /* GYLog_h */
