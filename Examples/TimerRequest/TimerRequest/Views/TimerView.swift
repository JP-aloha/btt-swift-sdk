//
//  TimerView.swift
//  TimerRequest
//
//  Created by Mathew Gacy on 7/31/22.
//

import BlueTriangle
import SwiftUI

struct TimerView: View {
    enum FocusField: Hashable {
        case sessionID
        case abTestID
        case campaignMedium
        case campaignName
        case campaignSource
        case dataCenter
        case trafficSegmentName
        case pageName
        case pageType
        case brandValue
        case referringURL
        case url
        case cartValue
        case orderNumber
        case orderTime
    }

    @FocusState var focusedField: FocusField?
    @StateObject var viewModel: TimerViewModel
    @State var showDetail = false

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Session"),
                    footer: Text("Can only be set during initial configuration")
                ) {
                    LabeledView("Site ID") {
                        Text(viewModel.siteID)
                            .foregroundColor(.gray)
                    }
                    LabeledView("Global User ID") {
                        Text(viewModel.globalUserID)
                            .foregroundColor(.gray)
                    }
                }

                Section(header: Text("Session")) {
                    Toggle("Returning Visitor", isOn: $viewModel.isReturningVisitor)
                    LabeledView("Session ID") {
                        TextField("", text: $viewModel.sessionID)
                            .keyboardType(.numbersAndPunctuation)
                            .disabled(true)
                    }
                    LabeledView("A/B Test ID") {
                        TextField("", text: $viewModel.abTestID)
                            .focused($focusedField, equals: .abTestID)
                    }
                    LabeledView("Campaign Medium") {
                        TextField("", text: $viewModel.campaignMedium)
                            .focused($focusedField, equals: .campaignMedium)
                    }
                    LabeledView("Campaign Name") {
                        TextField("", text: $viewModel.campaignName)
                            .focused($focusedField, equals: .campaignName)
                    }
                    LabeledView("Campaign Source") {
                        TextField("", text: $viewModel.campaignSource)
                            .focused($focusedField, equals: .campaignSource)
                    }
                    LabeledView("Data Center") {
                        TextField("", text: $viewModel.dataCenter)
                            .focused($focusedField, equals: .dataCenter)
                    }
                    LabeledView("Traffic Segment Name") {
                        TextField("", text: $viewModel.trafficSegmentName)
                            .focused($focusedField, equals: .trafficSegmentName)
                    }
                }

                Section(header: Text("Page")) {
                    LabeledView("Page Name") {
                        TextField("", text: $viewModel.page.pageName)
                            .focused($focusedField, equals: .pageName)
                    }
                    LabeledView("Page Type") {
                        TextField("", text: $viewModel.page.pageType)
                            .focused($focusedField, equals: .pageType)
                    }
                    LabeledView("Brand Value") {
                        TextField("", value: $viewModel.page.brandValue, formatter: NumberFormatter.decimal)
                            .keyboardType(.numbersAndPunctuation)
                            .focused($focusedField, equals: .brandValue)
                    }
                    LabeledView("Referring URL") {
                        TextField("", text: $viewModel.page.referringURL)
                            .keyboardType(.URL)
                            .focused($focusedField, equals: .referringURL)
                    }
                    LabeledView("URL") {
                        TextField("", text: $viewModel.page.url)
                            .keyboardType(.URL)
                            .focused($focusedField, equals: .url)
                    }
                }

                Section(
                    header: HStack {
                        Button {
                            viewModel.showPurchaseConfirmation.toggle()
                        } label: {
                            HStack {
                                Text("PURCHASE CONFIRMATION")
                                Spacer()
                                Image(systemName: "chevron.right.circle")
                                    .rotationEffect(.degrees(viewModel.showPurchaseConfirmation ? 90.0 : 0.0))
                                    .animation(.default, value: viewModel.showPurchaseConfirmation)
                            }
                        }
                    }
                ) {
                    if viewModel.showPurchaseConfirmation {
                        LabeledView("Cart Value") {
                            TextField(
                                "",
                                value: $viewModel.purchaseConfirmation.cartValue,
                                formatter: NumberFormatter.decimal)
                            .keyboardType(.numbersAndPunctuation)
                            .focused($focusedField, equals: .cartValue)
                        }
                        LabeledView("Order Numer") {
                            TextField("", text: $viewModel.purchaseConfirmation.orderNumber)
                                .focused($focusedField, equals: .orderNumber)
                        }
                        LabeledView("Order Time") {
                            TextField(
                                "",
                                value: $viewModel.purchaseConfirmation.orderTime,
                                formatter: NumberFormatter.integer)
                            .keyboardType(.numbersAndPunctuation)
                            .focused($focusedField, equals: .orderTime)
                        }
                    }
                }
            }
            .bttTrackScreen("Time View")
            .onSubmit {
                switch focusedField {
                case .sessionID:
                    focusedField = .abTestID
                case .abTestID:
                    focusedField = .campaignMedium
                case .campaignMedium:
                    focusedField = .campaignName
                case .campaignName:
                    focusedField = .campaignSource
                case .campaignSource:
                    focusedField = .dataCenter
                case .dataCenter:
                    focusedField = .trafficSegmentName
                case .trafficSegmentName:
                    focusedField = .pageName
                case .pageName:
                    focusedField = .pageType
                case .pageType:
                    focusedField = .brandValue
                case .brandValue:
                    focusedField = .referringURL
                case .referringURL:
                    focusedField = .url
                case .url:
                    focusedField = .cartValue
                case .cartValue:
                    focusedField = .orderNumber
                case .orderNumber:
                    focusedField = .orderTime
                case .orderTime:
                    return
                case .none:
                    return
                }
            }
            .navigationBarTitle("Timer", displayMode: .automatic)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: {
                        Task {
                            await viewModel.submit()
                            if viewModel.timerFields != nil {
                                showDetail = true
                            }
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Submit")
                        }
                    }
                    .disabled(viewModel.hasPendingTimer)

                    Spacer()

                    Button("Clear") {
                        viewModel.clear()
                    }
                }
            }
        }
        .sheet(isPresented: $showDetail, onDismiss: { viewModel.timerFields = nil}) {
            TimerRequestView(shouldDisplay: $showDetail, timerFields: viewModel.timerFields ?? [:])
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView(viewModel: .init())
    }
}
