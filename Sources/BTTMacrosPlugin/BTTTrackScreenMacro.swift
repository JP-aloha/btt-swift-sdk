//
//  BTTTrackScreenMacro.swift
//  blue-triangle
//
//  Created by Ashok Singh on 10/04/26.
//

#if os(macOS)
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct BTTTrackScreenMacro {}

extension BTTTrackScreenMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // MARK: - Validate struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(node: node, message: BTTDiagnostic(message: "BTTTrackScreen can only be applied to structs"))
            )
            throw BTTMacroError.notStruct
        }
        
        // MARK: - Validate View conformance
        let inheritsView =
        structDecl.inheritanceClause?.inheritedTypes.contains {
            if let ident = $0.type.as(IdentifierTypeSyntax.self) {
                return ident.name.text == "View"
            }
            if let member = $0.type.as(MemberTypeSyntax.self),
               let base = member.baseType.as(IdentifierTypeSyntax.self),
               base.name.text == "SwiftUI",
               member.name.text == "View" {
                return true
            }
            return false
        } ?? false
        
        guard inheritsView else {
            context.diagnose(
                Diagnostic(node: node, message: BTTDiagnostic(message: "Struct must conform to View to use BTTTrackScreen"))
            )
            throw BTTMacroError.notConformingToView
        }
        
        // MARK: - Find body
        guard let bodyVar = structDecl.memberBlock.members
            .compactMap({ $0.decl.as(VariableDeclSyntax.self) })
            .first(where: {
                $0.bindings.first?
                    .pattern
                    .as(IdentifierPatternSyntax.self)?
                    .identifier.text == "body"
            })
        else {
            context.diagnose(
                Diagnostic(node: node, message: BTTDiagnostic(message: "Struct must have a `body` property to use BTTTrackScreen"))
                                                             )
                           throw BTTMacroError.noBody
        }
        
        // MARK: - Extract ONLY body statements (FIX)
        guard let declaration = bodyVar.bindings.first?.accessorBlock?.accessors._syntaxNode else {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: BTTDiagnostic(
                        message: "The `body` property must have an accessor block to use BTTTrackScreen")))
            throw BTTMacroError.noBody
        }
        
        let bodyContent = declaration.description
        
        // MARK: - Screen name
        let screenName: String = {
            if let arg = node.arguments?
                .as(LabeledExprListSyntax.self)?
                .first,
               let str = arg.expression.as(StringLiteralExprSyntax.self),
               let seg = str.segments.first?.as(StringSegmentSyntax.self) {
                return seg.content.text
            }
            return structDecl.name.text
        }()
        
        let structName = structDecl.name.text
        
        // MARK: - Generate code (SAFE)
        let syntax = DeclSyntax(
        """
        // MARK: - BTT Auto Generated
        
        @ViewBuilder
        private var _bttOriginalBody: some View {
        \(raw: bodyContent)
        }
        
        struct _BTTBodyContainer: View {
            let view: \(raw: structName)
            var body: some View {
                view._bttOriginalBody
            }
        }
        
        typealias Body = BTTTrackScreen<_BTTBodyContainer>
        
        @_implements(View, body)
        @inline(never)
        @ViewBuilder
        var _bttTrackedBody: Self.Body {
            BTTTrackScreen("\(raw: screenName)") {
                _BTTBodyContainer(view: self)
            }
        }
        """
        )
        
        return [syntax]
    }
}

// MARK: - Diagnostic
struct BTTDiagnostic: DiagnosticMessage {
    let message: String
    
    var diagnosticID: MessageID {
        .init(domain: "BTTMacro", id: "Error")
    }
    
    var severity: DiagnosticSeverity { .error }
}
#endif
