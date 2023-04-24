//
//  ANRTests.swift
//  TimerRequest
//
//  Created by jaiprakash bokhare on 29/03/23.
//

import Foundation

//@_silgen_name("mach_backtrace")
//public func backtrace(_ thread: thread_t, stack: UnsafeMutablePointer<UnsafeMutableRawPointer?>!, _ maxSymbols: Int32) -> Int32
protocol Test{
    func test()->String
}

struct ANRTestFactory{
    
    //static var SleepMainThreadTest : Test {get { SleepMainThreadTest() } }
    //static var HeavyTaskTest : Test {get { SleepMainThreadTest() } }
    //static var HeavyDownloadTest : Test {get { SleepMainThreadTest() } }
}

struct SleepMainThreadTest : Test{
    
    func test() -> String {
        DispatchQueue.main.async {
            Thread.sleep(forTimeInterval: 10)
        }
        return "MainThread will be sleep for 10 Sec."
    }
}

struct HeavyTaskTest : Test{
    
    func test() -> String {
        DispatchQueue.main.async {
            Thread.sleep(forTimeInterval: 10)
        }
        return "MainThread will be sleep for 10 Sec."
    }
}
