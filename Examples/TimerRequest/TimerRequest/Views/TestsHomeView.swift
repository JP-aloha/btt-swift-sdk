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
        }
    }
    
    @State var timer : BTTimer?
    func startTimer(){
        let page = Page(pageName:"Main Thread Performance Test Page")
        self.timer = BlueTriangle.startTimer(page: page)
    }
    
    func stopTimer(){
        if let t = timer{
            BlueTriangle.endTimer(t)
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
        //Aprox 25 Sec
        var count : Int = 0
        repeat{
            count += 1
            //NSLog("Count \(count)")
        }while(count < Int32.max)
        
        NSLog("TestCase Task Finished.")
    }
    
    func sleepTest(){
        Thread.sleep(forTimeInterval: 2)
        Thread.sleep(forTimeInterval: 7)
    }
}

struct TestsHomeView_Previews: PreviewProvider {
    static var previews: some View {
        TestsHomeView()
    }
}
