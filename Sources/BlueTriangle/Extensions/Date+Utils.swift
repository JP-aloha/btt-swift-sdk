//
//  Date+Utils.swift
//  
//
//  Created by Ashok Singh on 11/01/24.
//

import Foundation

extension Date {
    func adding(minutes: Int64) -> Date {
        return Calendar.current.date(byAdding: .minute, value: Int(minutes), to: self)!
    }
    
    static func addCurrentTimeInMinut(_ minut : Int64) -> Int64{
        let totalMilisecond = Date().adding(minutes: minut).timeIntervalSince1970.milliseconds
        return totalMilisecond
    }
}
