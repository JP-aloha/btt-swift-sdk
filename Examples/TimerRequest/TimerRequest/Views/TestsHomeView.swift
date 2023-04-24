//
//  TestsHomeView.swift
//  TimerRequest
//
//  Created by jaiprakash bokhare on 17/03/23.
//

import SwiftUI
import BlueTriangle

struct TestsHomeView: View {
    var body: some View {
        
        NavigationView{
            VStack{
                
                Text("Main Thread performance data Tests.")
                    .padding(.vertical)
                
                Button("Start Timer") {
                    startTimer()
                }.disabled(self.timer != nil)
                
                Button("Run Long loop on main thread") {
                    longRunningLoopTest()
                    //performTestWithTimer(testCase: longRunningLoopTest)
                }
                Button("Sleep Main Thread") {
                    sleepTest()
                    //performTestWithTimer(testCase: sleepTest)
                }
                
                Button("Stop Timer") {
                    stopTimer()
                }.disabled(self.timer == nil)
                
                Divider()
                    .padding(.vertical)
                Text("Timer Tests")
                    .padding(.vertical)
                NavigationLink("Timer View",
                               destination: TimerView(viewModel: TimerViewModel()))
                
            }
            .onAppear {
                anrWatchDog.start()
                //MainThreadTraceProvider.shared.setup()
            }
        }
    }
    
    @State var timer : BTTimer?
    @State var watchDog = ANRPerformanceMonitor()
    @State var anrWatchDog = ANRWatchDog(mainThreadObserver: MainThreadObserver())
    func startTimer(){
        let page = Page(pageName:"Main Thread Performance Test Page")
        self.timer = BlueTriangle.startTimer(page: page)
        MainThreadObserver.start()
        watchDog.start()
        //startSampleTimer()
        //startNormalSampleTimer()
    }
    
    func stopTimer(){
        if let t = timer{
            BlueTriangle.endTimer(t)
            timer = nil
        }
    }
    
   @State var bgTimer : DispatchSourceTimer?
    
    func startSampleTimer(){
        let queue = DispatchQueue(label: "com.domain.app.timer", attributes: .concurrent)
        // timerObject?.cancel()        // cancel previous timer if any
        bgTimer = DispatchSource.makeTimerSource(queue: queue)
        bgTimer?.schedule(deadline: DispatchTime.now(),
                          repeating: DispatchTimeInterval.seconds(1),
                          leeway: DispatchTimeInterval.never)
        bgTimer?.setEventHandler(handler: { () in
            NSLog("Sample Timer BG Fire...")
        })
        //timerObject.setEventHandler(handler: closure)
        bgTimer?.resume()
    }
    
    func startNormalSampleTimer(){
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            NSLog("Sample Timer FG Fire...")
        }
    }
    
    func performTestWithTimer(testCase : ()->Void){
        let page = Page(pageName:"Main Thread Performance Test Page")
        let timer = BlueTriangle.startTimer(page: page)
        
        testCase()
        
        BlueTriangle.endTimer(timer)
    }
    
    func longRunningLoopTest(){
        NSLog("TestCase Task Started.")
        scheduleMainThreadTrace(time: 5)
        //Aprox 25 Sec
        var count : Int = 0
        repeat{
            count += 1
            //NSLog("Count \(count)")
        }while(count < Int32.max)
        
        NSLog("TestCase Task Finished.")
    }
    
    func sleepTest(){
        NSLog("TestCase Task Started.")
        scheduleMainThreadTrace(time: 5)
        Thread.sleep(forTimeInterval: 30)
        //Thread.sleep(forTimeInterval: 7)
        NSLog("TestCase Task Finished.")
    }
    
    func scheduleMainThreadTrace(time : TimeInterval){
        return
//        DispatchQueue(label: "MainThreadTraceQueue")
//            .asyncAfter(deadline: DispatchTime.now() + time, execute: {
//                do{
//                    let trace = try MainThreadTraceProvider.shared.getTrace()
//                    print("Trace... \n \(trace)")
//                }catch{
//                    print("Exception getting trace. ")
//                }
//                
//            })
    }
}

struct TestsHomeView_Previews: PreviewProvider {
    static var previews: some View {
        TestsHomeView()
    }
}
