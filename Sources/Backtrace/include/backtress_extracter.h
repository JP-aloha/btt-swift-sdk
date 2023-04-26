//
//  backtress_extracter.h
//  TimerRequest
//
//  Created by jaiprakash bokhare on 19/04/23.
//

#ifndef backtress_extracter_h
#define backtress_extracter_h

#include <stdio.h>
#include <mach/mach.h>

void* get_backtrace(thread_t thread, int *trace_size);

#endif /* backtress_extracter_h */
