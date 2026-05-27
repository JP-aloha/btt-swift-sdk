import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            CellTitleView()
            List{
                CellView()
                CellView()
                CellView()
                CellView()
                CellView()
                CellView()
            }
            CellTitleView()
        }
    }
}

struct CellView: View {
    var body: some View {
        VStack{
            Text("Cell View Content")
        }
    }
}

struct CellTitleView: View {
    var body: some View {
        VStack{
            Text("About")
        }
    }
}
