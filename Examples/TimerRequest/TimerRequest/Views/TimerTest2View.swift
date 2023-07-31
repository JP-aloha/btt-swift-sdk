//
//  TimerTest2View.swift
//  TimerRequest
//
//  Created by Ashok Singh on 31/07/23.
//

import SwiftUI

struct TimerTest2View: View {
    var body: some View {
        VStack{
            Text("TimerTest2View")
            Text("Sleep on Appear 5 sec")
        }
        .bttTrackScreen("TimerTest2View")
        .onAppear{
            Thread.sleep(forTimeInterval: 5)
        }
    }
}

struct TimerTest2View_Previews: PreviewProvider {
    static var previews: some View {
        TimerTest2View()
    }
}
