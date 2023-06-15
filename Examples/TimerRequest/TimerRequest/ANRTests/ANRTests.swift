//
//  ANRTests.swift
//  TimerRequest
//
//  Created by JP on 29/03/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

struct TestScheduler{
    
    enum Event{
        case OnAppLaunch
        case OnResumeFromBackground
    }
    
    static func schedule(){
        
    }
}

protocol BTTTestCase{
    
    func run()->String?
    var name : String {get}
    var description : String {get}
    
}

struct ANRTestFactory{
    
    func ANRTests() -> [any BTTTestCase]{
        return [
        SleepMainThreadTest(),
        HeavyLoop(),
        DownloadTest(),
        DeadLockMainThreadTest(),
        NSExceptionTest()
        ]
    }
}

struct SleepMainThreadTest : BTTTestCase{
    
    var interval : TimeInterval = 10
    var name: String { "Sleep MainThread \(interval) Sec." }
    var description: String {"This test calls Thread.sleep for \(interval) on main thread."}
    
    func run() -> String? {
        Thread.sleep(forTimeInterval: 10)
        return nil
    }
}

struct HeavyLoop : BTTTestCase{
    
    var interval : TimeInterval = 8
    var name: String { "HeavyLoop \(interval) Sec." }
    var description: String {"This test creates an array of 20K random strings, loops thru this array many times to find numbers in these strings till \(interval) Sec."}
    
    func run() -> String? {
        task(taskStartTime: Date())
        return nil
    }
    
    private func task(taskStartTime : Date){
        var list : [String] = []
        var generator = SystemRandomNumberGenerator()
        repeat{
            list.append("\(Int.random(in: 1...Int.max, using: &generator))")
        
            if Date().timeIntervalSince(taskStartTime) >= interval {return}
            
        }while(list.count < 20000)
        
        var duplicates = 0
        for number in list{
           
            var currentDuplicate = 0
            for n in list{
                if n == number{
                    currentDuplicate += 1
                }
                if Date().timeIntervalSince(taskStartTime) >= interval {return}
            }
            
            duplicates += (currentDuplicate - 1)
            if Date().timeIntervalSince(taskStartTime) >= interval {return}
        }
        
        if Date().timeIntervalSince(taskStartTime) < interval {
            task(taskStartTime: taskStartTime)
        }
    }
}

struct DownloadTest : BTTTestCase{
    
    var interval : TimeInterval = 10
    var name: String { "Download on MainThread \(interval) Sec." }
    var description: String {"This test downloads 200MB file in loop until \(interval) Sec."}
    
    func run() -> String? {
        task()
        return nil
    }
    
    private func task(){
        let taskStartTime = Date()
        var totalBytesDownloded = 0
        
        repeat{
            let data = try? Data(contentsOf: URL("http://ipv4.download.thinkbroadband.com/200MB.zip"))
            totalBytesDownloded += data?.count ?? 0
        }while(Date().timeIntervalSince(taskStartTime) < interval)
        
    }
}

struct DeadLockMainThreadTest : BTTTestCase{
    
    var interval : TimeInterval = 10
    var name: String { "DeadLock MainThread \(interval) Sec." }
    var description: String {"This test calls Thread.sleep for \(interval) on main thread."}
    
    func run() -> String? {
        return nil
    }
}

struct NSExceptionTest : BTTTestCase{
    
    var interval : TimeInterval = 10
    var name: String { "NSException Test" }
    var description: String {"Throws an NSException."}
    
    func run() -> String? {
        let arr = NSArray()
        NSLog("Not found element \(arr[1])")
        return nil
    }
}

