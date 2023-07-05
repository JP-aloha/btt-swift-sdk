//
//  TimerRequestView.swift
//  TimerRequest
//
//  Created by Mathew Gacy on 7/31/22.
//

import SwiftUI

struct TimerRequestView: View {
    @Binding var shouldDisplay: Bool
    var timerFields: [String: String]
    var requestRepresentation: String {
        timerFields.reduce( "{", { $0 + "\n  \"\($1.key)\": \($1.value)," }) + "\n}"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                Text(requestRepresentation)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.all, 8)
            }
            .onTapGesture {
                shouldDisplay = false
            }
            .navigationBarTitle("Request Body")
            .navigationBarTitleDisplayMode(.inline)
            .bttTrackScreen("TimerRequestView")
        }
    }
}

struct TimerRequestView_Previews: PreviewProvider {
    static var previews: some View {
        TimerRequestView(shouldDisplay: .constant(true), timerFields: PreviewData.timerFields)
    }
}
