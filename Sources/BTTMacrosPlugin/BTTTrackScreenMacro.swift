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
                Diagnostic(node: node, message: BTTDiagnostic(message: "Only structs supported"))
            )
            return []
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
                Diagnostic(node: node, message: BTTDiagnostic(message: "Must conform to View"))
            )
            return []
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
                Diagnostic(node: node, message: BTTDiagnostic(message: "Missing body"))
            )
            return []
        }

        // MARK: - Extract ONLY body statements (FIX)
        guard let _ = bodyVar.bindings.first?.accessorBlock else {
            context.diagnose(
                Diagnostic(node: node, message: BTTDiagnostic(message: "Invalid body"))
            )
            return []
        }

        guard let accessor = bodyVar.bindings.first?.accessorBlock?.accessors._syntaxNode else {
            context.diagnose(
                Diagnostic(node: node, message: BTTDiagnostic(message: "Missing body"))
            )
            return []
        }

        let bodyContent = accessor.description

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
