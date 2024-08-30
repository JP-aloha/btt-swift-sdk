//
//  SignalHandler.m
//  signal_handler
//
//  Created by jaiprakash  on 29/05/24.
//

#import "SignalHandler.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <signal.h>
#include <dlfcn.h>
#include <pthread.h>
#include <mach/mach.h>

void register_btt_tracker(void);
void reset_sig_handlers(void);
void register_alt_stack(void);
void register_prev_alt_stack(void);
void register_prev_handlers(void);

int register_handler(int, struct sigaction *);
void btt_signal_handler(int, siginfo_t*, void*);

char* make_report(char*, siginfo_t*, time_t);

void print_reg_status(void);



#define SIG_COUNT 8
int signals[SIG_COUNT] = {SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGSEGV, SIGSYS, SIGTRAP, SIGTERM};
char* signal_names[SIG_COUNT] = {"SIGABRT", "SIGBUS", "SIGFPE", "SIGILL", "SIGSEGV", "SIGSYS", "SIGTRAP", "SIGTERM"};
struct sigaction sigaction_prv_handlers[SIG_COUNT] = {NULL};
int sig_reg_status[SIG_COUNT] = {0};

static bool __debug_log = false;
static char* __app_version = "unknown";
static char* __report_folder_path = NULL;
static NSString* __current_page_name = @"";
static NSString* __btt_session_id = @"unknown";
static int __max_cache_files = 5;
static bool __is_register = false;

void register_btt_tracker(void){
    
    register_alt_stack();
    
    for (int sig_index = 0; sig_index <= SIG_COUNT - 1; sig_index++){
        sig_reg_status[sig_index] = register_handler(signals[sig_index], &sigaction_prv_handlers[sig_index]);
    }
}

void print_reg_status(void){
    
    NSLog(@"Signal handlers registration status.");
    
    for (int sig_index = 0; sig_index <= SIG_COUNT - 1; sig_index++){
        NSLog(@"Signal : %d", signals[sig_index]);
        if( sig_reg_status[sig_index] == 0 ){
            NSLog(@"registration successful");
            
            if(sigaction_prv_handlers[sig_index].sa_sigaction != NULL){
                NSLog(@"Previous handler was NOT default.");
            }else{
                NSLog(@"Previous handler was default");
            }
        } else {
            NSLog(@"registration got error : %d", sig_reg_status[sig_index]);
        }
    }
}

void reset_sig_handlers(void){
    
    for (int sig_index = 0; sig_index <= SIG_COUNT - 1; sig_index++){
        struct sigaction action;
        
        memset(&action, 0, sizeof(action));
        action.sa_handler = SIG_DFL;
        sigemptyset(&action.sa_mask);
        
        if (sigaction(signals[sig_index], &action, NULL) != 0){
            [SignalHandler debug_log:[NSString stringWithFormat:@"Failed to reset handler for signal %d", signals[sig_index]]];
        }
    }
}

stack_t prevAltStack;

void register_alt_stack(void){
    stack_t altStack;
    prevAltStack.ss_sp = NULL;

    altStack.ss_sp = malloc(SIGSTKSZ * 2);
    altStack.ss_size = SIGSTKSZ;
    altStack.ss_flags = 0;
    
#if TARGET_OS_IOS
    if (sigaltstack(&altStack, &prevAltStack))
        [SignalHandler debug_log:@"Failed to register alt stack."];
#endif
}

void register_prev_alt_stack(void){
    
    if (prevAltStack.ss_sp == NULL){
        return;
    }
    
#if TARGET_OS_IOS
    if (sigaltstack(&prevAltStack, NULL))
        [SignalHandler debug_log:@"Failed to register previous alt stack."];
#endif
}

void register_prev_handlers(void){
    for (int sig_index = 0; sig_index <= SIG_COUNT - 1; sig_index++){
        if ( sigaction_prv_handlers[sig_index].sa_sigaction != NULL) {
            
            if (sigaction(signals[sig_index], &sigaction_prv_handlers[sig_index], NULL) != 0){
                [SignalHandler debug_log:[NSString stringWithFormat:@"Failed to register previous handler for signal %d.", signals[sig_index]]];
            }
        }
    }
}

int register_handler(int signal, struct sigaction *prev_act){

    struct sigaction act;

    memset(&act, 0, sizeof(struct sigaction));
    sigemptyset(&act.sa_mask);

    act.sa_sigaction = &btt_signal_handler;

    act.sa_flags = SA_SIGINFO;
    prev_act->sa_sigaction = NULL;
    
    int result = sigaction(signal, &act, prev_act);
    
    if (*prev_act->sa_sigaction != NULL){
        [SignalHandler debug_log:[NSString stringWithFormat:@"Found a previously registered handler for signal %d", signal]];
    }
    
    return  result;
}

void btt_signal_handler(int signo, siginfo_t *sinfo, void *context)
{
    [SignalHandler debug_log:[NSString stringWithFormat:@"Received crash signal %d", signo]];

    //reset handlers to defaults
    reset_sig_handlers();
    
    char* name = "UNKNOWN";
    for (int sig_index = 0; sig_index <= SIG_COUNT - 1; sig_index++){
        if (signals[sig_index] == signo){
            name = signal_names[sig_index];
            break;
        }
    }
    
    time_t crash_time = time(NULL);
    char* crash_report = make_report(name, sinfo, crash_time);
    char* file_name = calloc(51, sizeof(char));
    snprintf(file_name, 50, "%ld.bttcrash", crash_time);
    
    [SignalHandler writeCrashReport:crash_report toReportFolderPath:__report_folder_path withfileName:file_name];
    
    [SignalHandler debug_log:[NSString stringWithFormat:@"Written btt crash %s\n%s", file_name, crash_report]];
    
    //call previous handler
    for (int sig_index = 0; sig_index <= SIG_COUNT - 1; sig_index++){
            
        if (signals[sig_index] == signo){
            
            if(sigaction_prv_handlers[sig_index].sa_sigaction != NULL){
                [SignalHandler debug_log:[NSString stringWithFormat:@"Found Previous signal handler for %d calling it", signo]];
                sigaction_prv_handlers[sig_index].sa_sigaction(signo, sinfo, context);
            }
            
            break;
        }
    }
    
    //reset alt stack to previous
    register_prev_alt_stack();
    //register previous handlers
    register_prev_handlers();
}

char* make_report(char* sig_name, siginfo_t* sinfo, time_t crash_time){
    const char *report_templet = "{"
    " \"signal\" : \"%s\","
    " \"signo\" : %d, "
    " \"errno\" : %d, "
    " \"sig_code\" : %d, "
    " \"exit_value\" : %d, "
    " \"crash_time\" : %ld, "
    " \"app_version\" : \"%s\", "
    " \"btt_session_id\" : \"%s\", "
    " \"btt_page_name\" : \"%s\", "
    "}";

    const int crash_title_size = 256;
    char crash_title[256] = {0};
    char *code_line = "";

    switch (sinfo->si_signo) {
        case SIGABRT:
            snprintf(crash_title, crash_title_size, "SIGABRT (6) abort() %d", sinfo->si_code);
            break;
        case SIGBUS:
            switch (sinfo->si_code) {
                case BUS_ADRALN:
                    code_line = "Invalid address alignment (1)";
                    break;
                case BUS_ADRERR:
                    code_line = "Nonexistent physical address (2)";
                    break;
                case BUS_OBJERR:
                    code_line = "Nonexistent physical address (2)";
                    break;
            }
            snprintf(crash_title, crash_title_size, "SIGBUS (10) bus error invalid address 0x%llx, %s", (uint64_t)sinfo->si_addr, code_line);
            break;
        case SIGFPE:
            switch (sinfo->si_code) {
                case FPE_FLTDIV:
                    code_line = "floating point divide by zero (1)";
                    break;
                case FPE_FLTOVF:
                    code_line = "floating point overflow (2)";
                    break;
                case FPE_FLTUND:
                    code_line = "floating point underflow (3)";
                    break;
                case FPE_FLTRES:
                    code_line = "floating point inexact result (4)";
                    break;
                case FPE_FLTINV:
                    code_line = "invalid floating point operation (5)";
                    break;
                case FPE_FLTSUB:
                    code_line = "subscript out of range (6)";
                    break;
                case FPE_INTDIV:
                    code_line = "integer divide by zero (7)";
                    break;
                case FPE_INTOVF:
                    code_line = "integer overflow (8)";
                    break;
            }
            snprintf(crash_title, crash_title_size, "SIGFPE (8) floating point exception at 0x%llx, %s", (uint64_t)sinfo->si_addr, code_line);
            break;
        case SIGILL:
            switch (sinfo->si_code) {
                case ILL_ILLOPC:
                    code_line = "illegal opcode (1)";
                    break;
                case ILL_ILLTRP:
                    code_line = "illegal trap (2)";
                    break;
                case ILL_PRVOPC:
                    code_line = "privileged opcode (3)";
                    break;
                case ILL_ILLOPN:
                    code_line = "illegal operand (4)";
                    break;
                case ILL_ILLADR:
                    code_line = "illegal addressing mode (5)";
                    break;
                case ILL_PRVREG:
                    code_line = "privileged register (6)";
                    break;
                case ILL_COPROC:
                    code_line = "coprocessor error (7)";
                    break;
                case ILL_BADSTK:
                    code_line = "internal stack error (8)";
                    break;
            }
            snprintf(crash_title, crash_title_size, "SIGILL(4) illegal instruction 0x%llx, %s", (uint64_t)sinfo->si_addr, code_line);
            break;
        case SIGSEGV:
            switch (sinfo->si_code) {
                case SEGV_MAPERR:
                    code_line = "address not mapped to object (1)";
                    break;
                case SEGV_ACCERR:
                    code_line = "invalid permission for mapped object (2)";
                    break;
            }
            snprintf(crash_title, crash_title_size, "SIGSEGV(11) segmentation violation 0x%llx, %s", (uint64_t)sinfo->si_addr, code_line);
            break;
        case SIGSYS:
            snprintf(crash_title, crash_title_size, "SIGSYS (12) bad argument to system call");
            break;
        case SIGTRAP:
            switch (sinfo->si_code) {
                case TRAP_BRKPT:
                    code_line = "Process breakpoint (1)";
                    break;
                case TRAP_TRACE:
                    code_line = "Process trace trap (2)";
                    break;
            }
            snprintf(crash_title, crash_title_size, "SIGTRAP (5) trace trap, %s", code_line);
            break;
        case SIGTERM:
            snprintf(crash_title, crash_title_size, "SIGTERM (15) termination signal from kill.");
            break;
            
        default:
            break;
    }
    
    const char* btt_pageName = "";
    NSString *nspagename = __current_page_name;
    if(__current_page_name != nil){
        btt_pageName = [nspagename cStringUsingEncoding:NSASCIIStringEncoding];
        if (btt_pageName == NULL)
            btt_pageName = "";
    }
    
    const char* btt_sessionid = "";
    NSString *bttsessionid = __btt_session_id;
    if(__btt_session_id != nil){
        btt_sessionid = [bttsessionid cStringUsingEncoding:NSASCIIStringEncoding];
        if (btt_sessionid == NULL)
            btt_sessionid = "";
    }
    
    unsigned long size_of_values = (sizeof(int) * 4) + strlen(sig_name) + sizeof(time_t) + strlen(crash_title);
    unsigned long bufferSize = strlen(report_templet) + (size_of_values * 3); //take size of values 3 times more just for safety
    char* report = calloc( bufferSize, sizeof(char));
    
    int actual_len = snprintf(report, bufferSize, report_templet,
                              crash_title,
                              sinfo->si_signo,
                              sinfo->si_errno,
                              sinfo->si_code,
                              sinfo->si_status,
                              crash_time,
                              __app_version,
                              btt_sessionid,
                              btt_pageName);

    if (actual_len > bufferSize)
        [SignalHandler debug_log:[NSString stringWithFormat:@"bttcrash report buffer is shorter then expected Expected %d found %lu", actual_len, bufferSize]];
    
    return report;
}


@implementation SignalHandler

+ (void) disableCrashTracking{
    
#if TARGET_OS_IOS
    reset_sig_handlers();
    register_prev_alt_stack();
    register_prev_handlers();
    
    [self debug_log:@"Disabled crash tracking. "];
#endif
    
}

+ (void) enableCrashTrackingWithApp_version:(NSString*) app_version
                debug_log:(Boolean) debug_log
                BTTSessionID:(NSString*) session_id{
    
    //Create report report folder if not found
    NSError *e = [self initReportFolderPath];
    if(e){
         [self debug_log:[NSString stringWithFormat:@"Error initialising crash report folder. %@", e]];
        return;
    }

    //Copy app version
    unsigned int size = MAX((unsigned int)app_version.length, 32) + 1; //including last \0
    char *buff = calloc(size, sizeof(char));
    [app_version getCString:buff maxLength:size encoding:NSASCIIStringEncoding];

    __app_version = buff;
    
    //copy logging status
    __debug_log = debug_log;

    //Copy sessionID
    __btt_session_id =  session_id;

#if TARGET_OS_IOS
    if (__is_register) {
        [self debug_log:[NSString stringWithFormat:@"Signal already registered."]];
       return;
    }
    
    //Register all Signal handlers
    register_btt_tracker();
    
    __is_register = true;
    
    [self debug_log:[NSString stringWithFormat:@"Signal registration successful session %@, version %s", __btt_session_id, __app_version]];
#endif
    
}

+ (NSString*) reportsFolderPath{
    return [NSString stringWithCString:__report_folder_path encoding:NSASCIIStringEncoding];
}

+ (NSError*) initReportFolderPath{
    NSURL* cache_folder_url = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
    NSString* report_folder_path = [cache_folder_url URLByAppendingPathComponent:@"btt_signals_tracks" isDirectory:YES].path;
    
    if (report_folder_path != nil){
        bool isFolder = false;
        
        if ( [[NSFileManager defaultManager] fileExistsAtPath:report_folder_path isDirectory:&isFolder]){
            if (!isFolder){
                return [NSError errorWithDomain:@"BTTSignal Handler"
                                           code:1
                                       userInfo:@{NSDebugDescriptionErrorKey : @""}];
            }
        }else{
            NSError *error = nil;
            [[NSFileManager defaultManager]
             createDirectoryAtPath:report_folder_path
             withIntermediateDirectories:NO
             attributes:nil
             error:&error];
            
            if (error)
                return error;
        }
    }else{
        return [NSError errorWithDomain:@"BTTSignal Handler"
                                   code:1
                               userInfo:@{NSDebugDescriptionErrorKey : @"Nil report folder path."}];
    }
    
    unsigned int size = (unsigned int)report_folder_path.length + 1; //including last \0
    char *buff = calloc(size, sizeof(char));
    [report_folder_path getCString:buff maxLength:size encoding:NSASCIIStringEncoding];
    
    __report_folder_path = buff;

    return  nil;
}

+ (void) writeCrashReport:(char*) report toReportFolderPath:(char*) folderPath withfileName:(char*) fileName{
    
    if (report == nil){
        [self debug_log:@"BTT::Error saving crash data, nil report."];
        return;
    }
        
    if (folderPath == nil){
        [self debug_log:@"BTT::Error saving crash data, nil cache folder."];
        return;
    }

    if (fileName == nil){
        [self debug_log:@"BTT::Error saving crash data, nil report file name."];
        return;
    }
    
    NSString *report_str = [NSString stringWithCString:report encoding:NSASCIIStringEncoding];
    NSString *folderPath_str = [NSString stringWithCString:folderPath encoding:NSASCIIStringEncoding];
    NSString *fileName_str = [NSString stringWithCString:fileName encoding:NSASCIIStringEncoding];
    
    NSString *crashFilePath = [folderPath_str stringByAppendingPathComponent:fileName_str];
    
    NSError *error = NULL;
    
    if(![report_str writeToFile:crashFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error]){
        [self debug_log:[NSString stringWithFormat:@"Error writing crash %@ at file %@. %@", report_str, crashFilePath, error]];
    }
    
    [self clearOlderCrashFiles];
}

+ (void)clearOlderCrashFiles{
    
    NSMutableArray<NSString *> *fileList = [NSMutableArray array];
    NSString *directory = [self reportsFolderPath];
    NSError *error = NULL;
    NSInteger maxFiles = __max_cache_files;
    NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&error];

    if (!files) {
        [self debug_log:[NSString stringWithFormat:@"Error fetching crash files from %@. %@", directory, error]];
        return;
    }
    
    for (NSString *name in files) {
        if ([name containsString:@".bttcrash"]) {
            [fileList addObject:name];
        }
    }
    
    if (fileList.count > maxFiles) {
         // Sort files by the TimeInterval part of the filename
         [fileList sortUsingComparator:^NSComparisonResult(NSString *file1, NSString *file2) {
             NSString *timeInterval1 = [file1 stringByDeletingPathExtension];
             NSString *timeInterval2 = [file2 stringByDeletingPathExtension];
             return [timeInterval1 compare:timeInterval2 options:NSNumericSearch];
         }];

         // Delete old files if there are more than maxFiles
         while (fileList.count > maxFiles) {
             NSString *oldestFile = fileList.firstObject;
             NSString *filePath = [directory stringByAppendingPathComponent:oldestFile];
             if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
                 [self debug_log:[NSString stringWithFormat:@"Error deleting crash file %@ from %@. %@", oldestFile, directory, error]];
                 return;
             }
             [fileList removeObjectAtIndex:0];
         }
     }
}

+ (void) setCurrentPageName:(NSString*) page_name{
    __current_page_name = page_name;
}

+ (void) updateSessionID:(NSString*) session_id{
    __btt_session_id = session_id;
}

+ (void) debug_log:(NSString *)msg{
    if(__debug_log){
        NSLog(@"BlueTriangle:CrashTracker: %@", msg);
    }
}

@end
