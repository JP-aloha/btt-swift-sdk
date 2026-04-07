import Foundation
import SwiftSyntax
import SwiftParser

// MARK: - SwiftUI Rewriter

final class SwiftUIRewriter: SyntaxRewriter {

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {

        // Only structs conforming to View
        guard let inheritance = node.inheritanceClause,
              inheritance.description.contains("View") else {
            return super.visit(node)
        }

        let structName = node.name.text

        var updatedMembers: [MemberBlockItemSyntax] = []

        for member in node.memberBlock.members {

            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.description.contains("var body") else {
                updatedMembers.append(member)
                continue
            }

            let bodyText = varDecl.description

            // Skip if already instrumented
            if bodyText.contains(".bttTrackScreen") {
                updatedMembers.append(member)
                continue
            }

            let modified = """
            \(bodyText)
                .bttTrackScreen("\(structName)")
            """

            let parsed = Parser.parse(source: modified)

            if let newDecl = parsed.statements.first?.item.as(DeclSyntax.self) {
                let newMember = member.with(\.decl, newDecl)
                updatedMembers.append(newMember)
            } else {
                updatedMembers.append(member)
            }
        }

        let newNode = node.with(
            \.memberBlock.members,
             MemberBlockItemListSyntax(updatedMembers)
        )

        return super.visit(newNode)
    }
}

// MARK: - Runner

guard CommandLine.arguments.count > 1 else {
    print("❌ No file path provided")
    exit(1)
}

let filePath = CommandLine.arguments[1]

// Skip unwanted paths
if filePath.contains("/Pods/") ||
   filePath.contains("/DerivedData/") ||
   filePath.contains(".build") {
    exit(0)
}

do {
    let source = try String(contentsOfFile: filePath)

    // Only SwiftUI files
    guard source.contains("import SwiftUI") else {
        exit(0)
    }

    let tree = Parser.parse(source: source)

    let rewriter = SwiftUIRewriter()
    let modified = rewriter.visit(tree)

    try "\(modified)".write(toFile: filePath, atomically: true, encoding: .utf8)

    print("✅ Instrumented: \(filePath)")

} catch {
    print("❌ Failed: \(error)")
}
