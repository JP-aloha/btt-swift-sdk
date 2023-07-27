//
//  CrashSignal.swift
//  
//
//  Created by New user on 27/07/23.
//

import Foundation

struct CrashSignal {
    
    static func getSignalNumbeDetail(signal: Int) -> String {
        
        switch signal {
        case 1:
            return "\(signal) SIGHUP (hangup)"
        case 2:
            return "\(signal) SIGINT (interrupt)"
        case 3:
            return "\(signal) SIGQUIT (quit)"
        case 4:
            return "\(signal) SIGILL (illegal instruction (not reset when caught)"
        case 5:
            return "\(signal) SIGTRAP (trace trap (not reset when caught)"
        case 6:
            return "\(signal) SIGABRT (abort())"
        case 7:
            return "\(signal) SIGPOLL (pollable event ([XSR] generated, not supported)) OR \(signal) SIGEMT (EMT instruction)"
        case 8:
            return "\(signal) SIGFPE (floating point exception)"
        case 9:
            return "\(signal) SIGKILL kill (cannot be caught or ignored)"
        case 10:
            return "\(signal) SIGBUS (bus error)"
        case 11:
            return "\(signal) SIGSEGV (segmentation violation)"
        case 12:
            return "\(signal) SIGSYS (bad argument to system call)"
        case 13:
            return "\(signal) SIGPIPE (write on a pipe with no one to read it)"
        case 14:
            return "\(signal) SIGALRM (alarm clock)"
        case 15:
            return "\(signal) SIGTERM (software termination signal from kill)"
        case 16:
            return "\(signal) SIGURG (urgent condition on IO channel)"
        case 17:
            return "\(signal) SIGSTOP (sendable stop signal not from tty)"
        case 18:
            return "\(signal) SIGTSTP (stop signal from tty)"
        case 19:
            return "\(signal) SIGCONT (continue a stopped process)"
        case 20:
            return "\(signal) SIGCHLD (to parent on child stop or exit)"
        case 21:
            return "\(signal) SIGTTIN (to readers pgrp upon background tty read)"
        case 22:
            return "\(signal) SIGTTOU (like TTIN for output if (tp->t_local&LTOSTOP))"
        case 23:
            return "\(signal) SIGIO (input/output possible signal)"
        case 24:
            return "\(signal) SIGXCPU (exceeded CPU time limit)"
        case 25:
            return "\(signal) SIGXFSZ (exceeded file size limit)"
        case 26:
            return "\(signal) SIGVTALRM (virtual time alarm)"
        case 27:
            return "\(signal) SIGPROF (profiling time alarm)"
        case 28:
            return "\(signal) SIGWINCH (window size changes)"
        case 29:
            return "\(signal) SIGINFO (information request)"
        case 30:
            return "\(signal) SIGUSR1 (user defined signal 1)"
        case 31:
            return "\(signal) SIGUSR2 (user defined signal 2)"
        default:
            return "\(signal)"
        }
    }
}
