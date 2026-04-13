import SwiftUI
import BlueTriangle

@BTTTrackScreen
struct DemoView: View {
    
    @State private var isShipActive: Bool = false
    @State private var isHomeActive: Bool = false
    @State private var isAboutActive: Bool = false
    
    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    VStack {
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
                        
                        NavigationLink(destination: AboutView() , isActive: $isAboutActive) {
                            Button("Go to About") {
                                isAboutActive = true
                            }
                        }
                    }
                }
            } else {
                NavigationView {
                    EmptyView()
                }
            }
        }
    }
}
