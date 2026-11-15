//
//  PurchaseConfirmation.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// An object describing a purchase confirmation interaction.
final public class PurchaseConfirmation: NSObject, @unchecked Sendable {
    private let lock = NSLock()

    private var _pageValue: Decimal = 0.0
    private var _cartValue: Decimal
    private var _orderNumber: String
    private var _cartCount: Int = 0
    private var _cartCountCheckout: Int = 0
    private var _orderTime: TimeInterval = 0.0

    /// Used by server to deduplicate `PurchaseConfirmation`s.
    internal var pageValue: Decimal {
        get { lock.sync { _pageValue } }
        set { lock.sync { _pageValue = newValue } }
    }
    
    /// Purchase amount for purchase confirmation steps.
    @objc public var cartValue: Decimal {
        get { lock.sync { _cartValue } }
        set { lock.sync { _cartValue = newValue } }
    }
    
    /// The order number from the purchase on purchase confirmation steps.
    @objc public var orderNumber: String {
        get { lock.sync { _orderNumber } }
        set { lock.sync { _orderNumber = newValue } }
    }
    
    /// Cart count  for purchase confirmation steps.
    @objc public var cartCount: Int {
        get { lock.sync { _cartCount } }
        set { lock.sync { _cartCount = newValue } }
    }
    
    /// Cart count checkout  for purchase confirmation steps.
    @objc public var cartCountCheckout: Int {
        get { lock.sync { _cartCountCheckout } }
        set { lock.sync { _cartCountCheckout = newValue } }
    }
    
    /// Order time and date.
    @objc public var orderTime: TimeInterval {
        get { lock.sync { _orderTime } }
        set { lock.sync { _orderTime = newValue } }
    }
    
    /// Creates a purchase confirmation.
    /// - Parameters:
    ///   - cartValue: Purchase amount.
    ///   - cartCount: Cart count.
    ///   - cartCountCheckout: Cart checkout count
    ///   - orderNumber: Order number.
    @objc
    public init(
        cartValue: Decimal,
        cartCount: Int = 0,
        cartCountCheckout: Int = 0,
        orderNumber: String = ""
    ) {
        _cartValue = cartValue
        _orderNumber = orderNumber
        _cartCount = cartCount
        _cartCountCheckout = cartCountCheckout
    }

    @objc
    public init(
        pageValue: Decimal = 0.0,
        cartValue: Decimal,
        cartCount: Int = 0,
        cartCountCheckout: Int = 0,
        orderNumber: String,
        orderTime: TimeInterval = 0.0
    ) {
        _pageValue = pageValue
        _cartValue = cartValue
        _orderNumber = orderNumber
        _orderTime = orderTime
        _cartCount = cartCount
        _cartCountCheckout = cartCountCheckout
    }

    // MARK: - Equality + dedup using snapshots

    private func snapshot() -> (pageValue: Decimal, cartValue: Decimal, orderNumber: String,
                                cartCount: Int, cartCountCheckout: Int, orderTime: TimeInterval) {
        lock.sync {
            (_pageValue, _cartValue, _orderNumber, _cartCount, _cartCountCheckout, _orderTime)
        }
    }
}
// MARK: - Equatable
public extension PurchaseConfirmation {
    static func == (lhs: PurchaseConfirmation, rhs: PurchaseConfirmation) -> Bool {
          let a = lhs.snapshot()
          let b = rhs.snapshot()
          return a.orderNumber == b.orderNumber && abs(a.orderTime - b.orderTime) <= TimeInterval.hour
      }
}

// MARK: - Codable (stored in the session as the last purchase confirmation)
extension PurchaseConfirmation: Codable {
    private enum CodingKeys: String, CodingKey {
        case pageValue, cartValue, orderNumber, cartCount, cartCountCheckout, orderTime
    }

    public convenience init(from decoder: Decoder) throws {
        let con = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            pageValue: try con.decode(Decimal.self, forKey: .pageValue),
            cartValue: try con.decode(Decimal.self, forKey: .cartValue),
            cartCount: try con.decode(Int.self, forKey: .cartCount),
            cartCountCheckout: try con.decode(Int.self, forKey: .cartCountCheckout),
            orderNumber: try con.decode(String.self, forKey: .orderNumber),
            orderTime: try con.decode(TimeInterval.self, forKey: .orderTime))
    }

    public func encode(to encoder: Encoder) throws {
        let s = snapshot()
        var con = encoder.container(keyedBy: CodingKeys.self)
        try con.encode(s.pageValue, forKey: .pageValue)
        try con.encode(s.cartValue, forKey: .cartValue)
        try con.encode(s.orderNumber, forKey: .orderNumber)
        try con.encode(s.cartCount, forKey: .cartCount)
        try con.encode(s.cartCountCheckout, forKey: .cartCountCheckout)
        try con.encode(s.orderTime, forKey: .orderTime)
    }
}

extension PurchaseConfirmation {
    /// A copy with the same values, so the stored last purchase is not affected by later changes to the caller's object.
    func makeCopy() -> PurchaseConfirmation {
        let s = snapshot()
        return PurchaseConfirmation(
            pageValue: s.pageValue,
            cartValue: s.cartValue,
            cartCount: s.cartCount,
            cartCountCheckout: s.cartCountCheckout,
            orderNumber: s.orderNumber,
            orderTime: s.orderTime)
    }

    /// Marks this purchase as a duplicate: the cart value is sent as page value and no revenue is counted.
    func deduplicate() {
        lock.sync {
            _pageValue = _cartValue
            _cartValue = 0.0
        }
    }
}
