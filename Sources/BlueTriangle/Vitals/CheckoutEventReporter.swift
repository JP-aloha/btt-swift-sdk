//
//  CheckoutEventReporter.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/02/26.
//

import Foundation

protocol CheckoutEvent {}

final actor CheckoutEventReporter {
    
    private let logger: Logging
    private var lastNetworkEvent: NetworkCheckoutEvent?
    private var lastClassEvent: ClassCheckoutEvent?
    init(logger: Logging) { self.logger = logger }
    
    func onCheckoutEvent(_ event: CheckoutEvent) {
        self.reportLogFor(event, message: "BlueTriangle:CheckoutEventReporter - checkout event", debug: true)
        if isValidEvent(event) {
            fireCheckoutEvent(event)
        }
    }
    
    private func fireCheckoutEvent(_ event: CheckoutEvent) {
        if BlueTriangle.initialized,  let session = BlueTriangle.sessionData() {
            let timer = BlueTriangle.startTimer(
                page: Page(
                    pageName: Constants.autoCheckoutPageName))
            let pgtm = Millisecond(session.checkoutTimeValue) > Constants.minPgTm ? Millisecond(session.checkoutTimeValue) : Constants.minPgTm
            timer.nativeAppProperties.autoCheckout = true
            timer.pageTimeBuilder = {
                return pgtm
            }
            let purchaseConfirmation: PurchaseConfirmation = PurchaseConfirmation(
                cartValue: Decimal(session.checkoutAmount),
                cartCount: session.checkoutCartCount,
                cartCountCheckout:session.checkoutCartCountCheckout,
                orderNumber: session.checkoutOrderNumber)
            BlueTriangle.endTimer(
                timer,
                purchaseConfirmation: purchaseConfirmation)
            
            self.reportLogFor(event, message: "BlueTriangle:CheckoutEventReporter - Auto checkout event fired successfully")
        }
    }
    
    private func reportLogFor(_ event: CheckoutEvent, message: String, debug: Bool = false) {
        switch event {
        case let classEvent as ClassCheckoutEvent:
            if debug {
                logger.debug(message + " for class: \(classEvent.name)")
            } else {
                logger.info(message + " for class: \(classEvent.name)")
            }
        case let networkEvent as NetworkCheckoutEvent:
            if debug {
                logger.debug(message + " for network url: \(networkEvent.url) and status code \(networkEvent.statusCode ?? "")")
            } else {
                logger.info(message + " for network url: \(networkEvent.url) and status code \(networkEvent.statusCode ?? "")")
            }
        default:
            if debug {
                logger.debug(message)
            } else {
                logger.info(message)
            }
        }
    }
}

extension CheckoutEventReporter {
    
    private func isValidEvent(_ event: CheckoutEvent) -> Bool {

        guard let session = BlueTriangle.sessionData(),
              session.checkoutTrackingEnabled else {
            return false
        }

        switch event {

        case let classEvent as ClassCheckoutEvent:

            // Immediate duplicate block
            if let last = lastClassEvent,
               last.name == classEvent.name {
                return false
            }

            lastClassEvent = classEvent

            return session.checkoutClassName.contains(classEvent.name)


        case let networkEvent as NetworkCheckoutEvent:

            // Immediate duplicate block
            if let last = lastNetworkEvent,
               last.url == networkEvent.url && last.statusCode == networkEvent.statusCode {
                return false
            }

            lastNetworkEvent = networkEvent

            let matchesURL = networkEvent.url
                .matchesWildcard(session.checkoutURL)

            guard matchesURL else { return false }

            let isSuccessStatus: Bool = {
                if let codeString = networkEvent.statusCode,
                   let code = Int(codeString) {
                    return (200...299).contains(code)
                }
                return false
            }()

            return isSuccessStatus

        default:
            return false
        }
    }
}

struct ClassCheckoutEvent: CheckoutEvent {
    var name: String
}

struct NetworkCheckoutEvent: CheckoutEvent {
    var url: String
    var statusCode: String?
}
