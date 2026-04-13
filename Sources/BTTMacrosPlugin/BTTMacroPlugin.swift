import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct BTTMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BTTTrackScreenMacro.self
    ]
}
