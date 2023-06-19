//
//  ANRTests.swift
//  TimerRequest
//
//  Created by JP on 29/03/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

struct TestScheduler{
    
    enum Event: String, CaseIterable {
        case OnAppLaunch = "On App Launch"
        case OnResumeFromBackground = "On Resume From Background"
        case OnBecomingActive = "On Becoming Active"
    }
    
    static func schedule(task: BTTTestCase, event: Event) {
        let scheduledTask = UserDefaults.standard.value(forKey: "schduledTask")
        if var scheduledTask = scheduledTask as? [String: [String]] {
           
            if var tasksOnEvent = scheduledTask[event.rawValue] {
                if tasksOnEvent.isEmpty {
                    scheduledTask[event.rawValue] = [task.className]
                    UserDefaults.standard.set(scheduledTask, forKey: "schduledTask")
                } else if tasksOnEvent.contains(where: { $0 == task.className}) {
                    return
                } else {
                    tasksOnEvent.append(task.className)
                    scheduledTask[event.rawValue]  = tasksOnEvent
                    UserDefaults.standard.set(scheduledTask, forKey: "schduledTask")
                }
            } else {
                scheduledTask[event.rawValue] = [task.className]
                UserDefaults.standard.set(scheduledTask, forKey: "schduledTask")
            }
            
        } else {
            let addTask = [event.rawValue: [task.className]]
            UserDefaults.standard.set(addTask, forKey: "schduledTask")
        }
    }
    
    static func getSchedule(event: Event) -> [any BTTTestCase] {
        var testsToRun: [any BTTTestCase] = []
        if let scheduledTask = UserDefaults.standard.value(forKey: "schduledTask") as? [String: [String]],
           let taskOnEvent = scheduledTask.first(where: { $0.key == event.rawValue })?.value {
            for task in taskOnEvent {
                if let test = ANRTestFactory().ANRTests().first(where: {$0.className == task}) {
                   testsToRun.append(test)
                }
            }
        }
        deleteScheduledTests(event: event)
        return testsToRun
    }
    
    static func deleteScheduledTests(event: Event) {
        if var scheduledTask = UserDefaults.standard.value(forKey: "schduledTask") as? [String: [String]] {
            scheduledTask[event.rawValue] = []
            UserDefaults.standard.set(scheduledTask, forKey: "schduledTask")
        }
    }
}

protocol BTTTestCase{
    
    func run()->String?
    var name : String {get}
    var description : String {get}
    var className: String { get }
}

extension BTTTestCase {
    var className: String{
        get {
            return "\(type(of: self))"
        }
    }
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
        DispatchQueue.main.async {
                   DispatchQueue.main.sync {
                       print("daadLock occured")
                   }
               }
               return "Deadlock occured. Please restart app."
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
