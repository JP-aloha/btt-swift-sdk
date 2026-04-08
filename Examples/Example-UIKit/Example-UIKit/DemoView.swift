import SwiftUI

struct DemoView: View {
    
    @State private var isShipActive: Bool = false
    @State private var isHomeActive: Bool = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack {
                    Text("Hello")
                    NavigationLink(destination: ShipView() , isActive: $isShipActive) {
                        Button("Go to Ship") {
                            isShipActive = true
                        }
                    }
                    
                    NavigationLink(destination: HomeView() , isActive: $isHomeActive) {
                        Button("Go to Home") {
                            isHomeActive = true
                        }
                    }
                }
            }
        } else {
        }
    }
}

