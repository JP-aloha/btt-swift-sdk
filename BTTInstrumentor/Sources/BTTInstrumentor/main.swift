import Foundation
import SwiftSyntax
import SwiftParser


/*
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

            // Skip if already injected
            if bodyText.contains(".bttTrackScreen") {
                updatedMembers.append(member)
                continue
            }

            // 🔥 FIXED INJECTION LOGIC
            let lines = bodyText.components(separatedBy: "\n")

            var modifiedLines: [String] = []
            var inserted = false

            for line in lines.reversed() {

                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // Find LAST closing brace of body
                if !inserted && trimmed == "}" {

                    modifiedLines.append("""
                        .bttTrackScreen("\(structName)")
                    """)
                    modifiedLines.append(line)

                    inserted = true
                } else {
                    modifiedLines.append(line)
                }
            }

            let finalBody = modifiedLines.reversed().joined(separator: "\n")

            // Parse modified body
            let parsed = Parser.parse(source: finalBody)

            if let newDecl = parsed.statements.first?.item.as(DeclSyntax.self) {
                let newMember = member.with(\.decl, newDecl)
                updatedMembers.append(newMember)

                print("✅ Instrumented: \(structName)")
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
   filePath.contains("/.build/") ||
   filePath.contains("BTTTool") {
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

} catch {
    print("❌ Failed: \(error)")
}
*/

import Foundation

guard CommandLine.arguments.count > 1 else {
    print("❌ No file path")
    exit(1)
}

let filePath = CommandLine.arguments[1]

print("👉 Processing:", filePath)

/*do {
    var source = try String(contentsOfFile: filePath)

    // ✅ Insert comment at top (only once)
    if !source.contains("// BTT_INJECTED") {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        let comment = "// BTT_INJECTED: \(fileName)\n"
        source = comment + source

        try source.write(toFile: filePath, atomically: true, encoding: .utf8)

        print("✅ Comment injected")
    } else {
        print("⚠️ Already injected")
    }

} catch {
    print("❌ Error:", error)
}*/

// Skip unwanted
/*if filePath.contains("/Pods/") || filePath.contains("BTTTool") {
    exit(0)
}*/

do {
    var source = try String(contentsOfFile: filePath)

    guard source.contains("import SwiftUI") else { exit(0) }

    // Avoid duplicate
    if source.contains(".bttTrackScreen") {
        print("⚠️ Already injected")
        exit(0)
    }

    // Find struct name
    guard let structMatch = source.range(of: #"struct\s+\w+\s*:\s*View"#, options: .regularExpression) else {
        exit(0)
    }

    let structLine = String(source[structMatch])
    let structName = structLine
        .replacingOccurrences(of: "struct", with: "")
        .replacingOccurrences(of: ": View", with: "")
        .trimmingCharacters(in: .whitespaces)

    print("📺 Injecting into:", structName)

    // 🔥 VERY SIMPLE: insert after first VStack closing brace
    if let range = source.range(of: "}") {

        let injection = "\n    .bttTrackScreen(\"\(structName)\")"

        source.insert(contentsOf: injection, at: range.upperBound)

        try source.write(toFile: filePath, atomically: true, encoding: .utf8)

        print("✅ Injected successfully")

    } else {
        print("❌ Could not find insertion point")
    }

} catch {
    print("❌ Error:", error)
}
