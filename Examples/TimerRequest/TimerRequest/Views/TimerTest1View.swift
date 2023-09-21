//
//  TimerTaskAppearView.swift
//  TimerRequest
//
//  Created by JP on 28/07/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.

import SwiftUI


struct TimerTest1View: View {
    var body: some View {
        VStack{
            Text("TimerTest1View")
            Text("Sleep on Appear 2 sec")
        }
        .bttTrackScreen("TimerTest1View")
        .onAppear{
            Thread.sleep(forTimeInterval: 2)
        }
    }
}

struct TimerTaskAppearView_Previews: PreviewProvider {
    static var previews: some View {
        TimerTest1View()
    }
}
