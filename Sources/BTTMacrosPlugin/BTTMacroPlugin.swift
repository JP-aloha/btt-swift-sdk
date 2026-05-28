//
//  BTTMacroPlugin.swift
//  blue-triangle
//
//  Created by Ashok Singh on 13/04/26.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct BTTMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BTTTrackMacro.self
    ]
}
