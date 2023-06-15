//
//  backtress_extracter.c
//  TimerRequest
//  Created by JP on 19/04/23.
//  Copyright © 2022 Blue Triangle. All rights reserved.

#include "backtress_extracter.h"
#include <stdio.h>
#include <stdlib.h>
#include <machine/_mcontext.h>

#if defined __i386__
#define THREAD_STATE_FLAVOR x86_THREAD_STATE
#define THREAD_STATE_COUNT  x86_THREAD_STATE_COUNT
#define __framePointer      __ebp

#elif defined __x86_64__
#define THREAD_STATE_FLAVOR x86_THREAD_STATE64
#define THREAD_STATE_COUNT  x86_THREAD_STATE64_COUNT
#define __framePointer      __rbp

#elif defined __arm__
#define THREAD_STATE_FLAVOR ARM_THREAD_STATE
#define THREAD_STATE_COUNT  ARM_THREAD_STATE_COUNT
#define __framePointer      __r[7]

#elif defined __arm64__
#define THREAD_STATE_FLAVOR ARM_THREAD_STATE64
#define THREAD_STATE_COUNT  ARM_THREAD_STATE64_COUNT
#define __framePointer      __fp

#else
#error "Current CPU Architecture is not supported"
#endif


void* get_backtrace(thread_t thread, int *trace_size){
    
    thread_t mainThread = mach_thread_self();

    _STRUCT_MCONTEXT machineContext;
    mach_msg_type_number_t stateCount = THREAD_STATE_COUNT;

    kern_return_t kret = thread_get_state(thread, THREAD_STATE_FLAVOR, (thread_state_t)&(machineContext.__ss), &stateCount);
    if (kret != KERN_SUCCESS) {
        return 0;
    }

    
    int maxTraceSize = 32; //lets only read max top 32 calls
    void** traceBuffer = calloc(maxTraceSize, sizeof(void*));
    int index = 0;
#if defined(__arm__) || defined (__arm64__)
    traceBuffer[index] = (void *)machineContext.__ss.__lr;
#endif
    void **currentFramePointer = (void **)machineContext.__ss.__framePointer;
    while (index < maxTraceSize) {
        void **previousFramePointer = *currentFramePointer;
        if (!previousFramePointer) break;
        
        traceBuffer[index] = *(currentFramePointer + 1);
        currentFramePointer = previousFramePointer;
        
        if (currentFramePointer == NULL) break;
        ++index;
    }
    
    *trace_size = index - 1;
    return  traceBuffer;
}
