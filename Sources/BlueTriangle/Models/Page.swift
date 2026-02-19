//
//  Page.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// An object describing a user interaction.
@objcMembers
final public class Page: NSObject, @unchecked Sendable {

    private let lock = NSLock()

    private var _brandValue: Decimal
    private var _pageName: String
    private var _pageTitle: String
    private var _pageType: String 
    private var _trafficSegment: String
    private var _referringURL: String
    private var _url: String

    @available(*, deprecated, message: "Use BlueTriangle 'setCustomVariables(_ variables : [:] )' methods instead.")
    private var _customVariables: CustomVariables?

    @available(*, deprecated, message: "Use BlueTriangle 'setCustomVariables(_ variables : [:] )' method instead.")
    private var _customCategories: CustomCategories?

    @available(*, deprecated, message: "Use BlueTriangle 'setCustomVariables(_ variables : [:] )' method instead.")
    private var _customNumbers: CustomNumbers?

    /// A static monetary amount assigned to a step in the user’s path.
    ///
    /// Signing up for a credit card, for example, is a zero-dollar transaction that
    /// nevertheless has business value.
    public var brandValue: Decimal {
        get { lock.sync { _brandValue } }
        set { lock.sync { _brandValue = newValue } }
    }

    /// Name of page.
    public var pageName: String {
        get { lock.sync { _pageName } }
        set { lock.sync { _pageName = newValue } }
    }
    
    /// Title of page.
    public var pageTitle: String {
        get { lock.sync { _pageTitle } }
        set { lock.sync { _pageTitle = newValue } }
    }

    /// Page or content grouping designation.
    public var pageType: String {
        get { lock.sync { _pageType } }
        set { lock.sync { _pageType = newValue } }
    }

    /// Referring URL.
    public var referringURL: String {
        get { lock.sync { _referringURL } }
        set { lock.sync { _referringURL = newValue } }
    }

    /// URL.
    public var url: String {
        get { lock.sync { _url } }
        set { lock.sync { _url = newValue } }
    }
    
    internal var trafficSegment : String {
        get { lock.sync { _trafficSegment } }
    }

    /// Custom textual data that is relevant to individual views but is not aggregated.
    @available(*, deprecated, message: "Use BlueTriangle 'setCustomVariables(_ variables : [:] )' methods instead.")
    public var customVariables: CustomVariables? {
        get { lock.sync { _customVariables } }
        set { lock.sync { _customVariables = newValue } }
    }

    /// Custom textual data that is aggregated and appears in the list of filter options
    /// in the Blue Triangle portal.
    @available(*, deprecated, message: "Use BlueTriangle 'setCustomVariables(_ variables : [:] )' method instead.")
    public var customCategories: CustomCategories? {
        get { lock.sync { _customCategories } }
        set { lock.sync { _customCategories = newValue } }
    }

    /// Custom numeric data that is aggregated and will appear on your trend graphs in
    /// the Blue Triangle portal.
    @available(*, deprecated, message: "Use BlueTriangle 'setCustomVariables(_ variables : [:] )' method instead.")
    public var customNumbers: CustomNumbers? {
        get { lock.sync { _customNumbers } }
        set { lock.sync { _customNumbers = newValue } }
    }

    @available(*, deprecated, message: "Use `init(pageName: ,brandValue: ,pageType: ,referringURL: ,url: )` instead.")
    public init(
        pageName: String,
        pageTitle: String = "",
        brandValue: Decimal = 0.0,
        pageType: String = "",
        referringURL: String = "",
        url: String = "",
        customVariables: CustomVariables? = nil,
        customCategories: CustomCategories? = nil,
        customNumbers: CustomNumbers? = nil,
        trafficSegment: String = ""
    ) {
        self._brandValue = brandValue
        self._pageName = pageName
        self._pageTitle = pageTitle
        self._pageType = pageType
        self._referringURL = referringURL
        self._url = url
        self._customVariables = customVariables
        self._customCategories = customCategories
        self._customNumbers = customNumbers
        self._trafficSegment = trafficSegment
        super.init()
    }

    public init(
        pageName: String,
        pageTitle: String = "",
        brandValue: Decimal = 0.0,
        pageType: String = "",
        referringURL: String = "",
        url: String = "",
        trafficSegment: String = ""
    ) {
        self._brandValue = brandValue
        self._pageName = pageName
        self._pageTitle = pageTitle
        self._pageType = pageType
        self._referringURL = referringURL
        self._trafficSegment = trafficSegment
        self._url = url
        super.init()
    }

    public override var description: String {
        let name = lock.sync { _pageName }
        return "<Page: \(name)>"
    }
}
