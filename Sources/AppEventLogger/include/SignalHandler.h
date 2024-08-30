//
//  SignalHandler.h
//  signal_handler
//
//  Created by jaiprakash bokhare on 29/05/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignalHandler : NSObject

+ (void) enableCrashTrackingWithApp_version:(NSString*) app_version
                debug_log:(Boolean) debug_log
                BTTSessionID:(NSString*) session_id;
+ (void) disableCrashTracking;

+ (NSString*) reportsFolderPath;

+ (void) writeCrashReport:(char*) report toReportFolderPath:(char*) folderPath withfileName:(char*) fileName;

+ (void) setCurrentPageName:(NSString*) page_name;

+ (void) updateSessionID:(NSString*) session_id;

+ (void) debug_log:(NSString *)msg;

@end

NS_ASSUME_NONNULL_END

