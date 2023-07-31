//
//  TestsHomeView.swift
//  TimerRequest
//
//  Created by JP on 17/03/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import SwiftUI

import BlueTriangle

struct TestsHomeView: View {
    @State var tests : [any BTTTestCase]
    @State var timer : BTTimer?
    @State var currentTest : BTTTestCase?
    @State var scheduleTestEvent: TestScheduler.Event = .OnAppLaunch
    
    var body: some View {
        
        NavigationView{
            ZStack{
                VStack{
                    List{
                        Section {
                            HStack{
                                Text("BTTimer : ")
                                if self.timer != nil {
                                    Text("Running ... ")
                                        .padding(.horizontal)
                                    Button("Stop") {
                                        stopTimer()
                                    }
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                }else{
                                    Spacer()
                                    Button("Start") {
                                        startTimer()
                                    }
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                        Section {
                            ForEach(tests, id: \.name) { test in
                                VStack{
                                    Text(test.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(test.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .onTapGesture {
                                    currentTest = test
                                }
                            }
                            
                        } header: {
                            VStack{
                                Text("ANR Tests")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Below are the ANR tests. If run while BTTimer, max main thread usage will be reported in BTTimer request.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }.textCase(.none)
                        
                        Section{
                            NavigationLink("Timer Request View",
                                           destination: TimerView(viewModel: TimerViewModel()))
                            
                            NavigationLink("Timer Test1 View",
                                           destination: TimerTest1View())
                            NavigationLink("Timer Test2 View",
                                           destination: TimerTest2View())
                            NavigationLink("Timer Test3 View",
                                           destination: TimerTest3View())
                            
                        }
                    }
                }
                
                if let test = currentTest{
                    VStack(spacing: 0){
                        VStack{
                            Rectangle()
                                .fill(.black)
                        }
                        .frame(maxHeight: .infinity)
                        .opacity(0.3)
                        VStack{
                            HStack{
                                Spacer()
                                Button("Close") {
                                    currentTest = nil
                                }
                            }
                            .padding()
                            Button("Run Now") {
                                let startTime = Date()
                                NSLog("Started Test \"\(test.name)\"")

                                _ = test.run()

                                NSLog("Finished Test \"\(test.name)\" in \(Date().timeIntervalSince(startTime)) Seconds")
                            }
                            .font(.headline)
                            .padding()
                            HStack(alignment: .center) {
                                Text("Schedule Runner")
                                    
                                Picker("Schedule", selection: $scheduleTestEvent) {
                                    ForEach(TestScheduler.Event.allCases, id: \.self) {
                                        Text($0.rawValue)
                                    }
                                }
                                
                                Button( "Set") {
                                    scheduleRunner()
                                }
                            }
                            .padding()
                            Text(test.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding()
                            Text(test.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.bottom, 100)
                        }
                        .frame(maxWidth:.infinity)
                        .background(.white)
                    }
                    .frame(maxWidth:.infinity)
                    .ignoresSafeArea()
                }
            }
            .bttTrackScreen("Tests Home View")
        }
    }
    
    func startTimer(){
        let page = Page(pageName:"Main Thread Performance Test Page")
        self.timer = BlueTriangle.startTimer(page: page)
    }
    
    func stopTimer(){
        if let t = timer{
            BlueTriangle.endTimer(t)
            timer = nil
        }
    }
    
    func scheduleRunner() {
        if let currentTest = currentTest {
            TestScheduler.schedule(task: currentTest, event: scheduleTestEvent)
        }
    }
}

struct TestsHomeView_Previews: PreviewProvider {
    static var previews: some View {
        TestsHomeView(tests: ANRTestFactory().ANRTests())
    }
}
