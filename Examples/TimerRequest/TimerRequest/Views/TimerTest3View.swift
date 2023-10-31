//
//  TimerTest3View.swift
//  TimerRequest
//
//  Created by JP on 31/07/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.

import SwiftUI

struct TimerTest3View: View {
    var body: some View {
        VStack{
            Text("TimerTest3View")
            Text("A heavy loop run")
        }
        .bttTrackScreen("TimerTest3View")
        .onAppear{
            let _ = HeavyLoop().run()
        }
    }
}

struct TimerTest3View_Previews: PreviewProvider {
    static var previews: some View {
        TimerTest3View()
    }
}
