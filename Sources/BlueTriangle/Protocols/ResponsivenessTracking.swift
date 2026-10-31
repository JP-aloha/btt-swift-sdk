//
//  ResponsivenessTracking.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

protocol ResponsivenessTracking {
    func start()
    func end()
    func makeReport() -> ResponsivenessReport
}
