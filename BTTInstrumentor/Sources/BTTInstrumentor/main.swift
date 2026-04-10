import Foundation

guard CommandLine.arguments.count > 1 else {
    print("❌ Missing file path")
    exit(1)
}

let filePath = CommandLine.arguments[1]
let backupPath = filePath + ".bttbackup"

// MARK: - RESTORE

if CommandLine.arguments.contains("--restore") {
    if FileManager.default.fileExists(atPath: backupPath),
       let backup = try? String(contentsOfFile: backupPath) {
        try? backup.write(toFile: filePath, atomically: true, encoding: .utf8)
        try? FileManager.default.removeItem(atPath: backupPath)
        print("♻️ Restored:", filePath)
    } else {
        print("⚠️ No backup found for:", filePath)
    }
    exit(0)
}

// MARK: - INJECT

do {
    let source = try String(contentsOfFile: filePath)

    guard source.contains("import SwiftUI") else {
        print("⏭ Skipping (no SwiftUI import):", filePath)
        exit(0)
    }

    // Already injected — skip
    if source.contains("_bttOriginalBody") {
        print("⚠️ Already injected:", filePath)
        exit(0)
    }

    // Backup original before touching anything
    if !FileManager.default.fileExists(atPath: backupPath) {
        try source.write(toFile: backupPath, atomically: true, encoding: .utf8)
    }

    // Find all View structs and inject each one
    let rewritten = injectAll(into: source)

    guard rewritten != source else {
        print("⏭ No View structs found:", filePath)
        exit(0)
    }

    try rewritten.write(toFile: filePath, atomically: true, encoding: .utf8)
    print("✅ Injected:", filePath)

} catch {
    print("❌ Error:", error)
    exit(1)
}

// MARK: - Inject All View Structs

func injectAll(into source: String) -> String {
    var result = source

    // Keep injecting from the top until no more un-injected View structs remain.
    // We restart from the beginning each pass because string indices are
    // invalidated after every replaceSubrange call.
    var safetyLimit = 100   // never loop forever on pathological input
    while safetyLimit > 0 {
        safetyLimit -= 1
        guard let match = findNextInjectableViewStruct(in: result) else { break }
        result = inject(into: result, match: match)
    }

    return result
}

// MARK: - Find Next Injectable View Struct

struct StructMatch {
    let structName: String
    let bodyVarRange: Range<String.Index>   // "var body: some View"
    let bodyOpenBrace: String.Index          // the `{` of the body block
    let bodyCloseBrace: String.Index         // the matching `}`
}

func findNextInjectableViewStruct(in source: String) -> StructMatch? {
    var cursor = source.startIndex

    while cursor < source.endIndex {

        // ── 1. Find next `struct <Name> ... : ... View` ──────────────────
        guard let structKwRange = source.range(
            of: #"\bstruct\s+([A-Za-z_][A-Za-z0-9_]*)"#,
            options: .regularExpression,
            range: cursor..<source.endIndex
        ) else { return nil }

        // Extract struct name
        let structName = extractName(from: String(source[structKwRange]))

        // Find the `{` that opens the struct body
        guard let structOpenBrace = source[structKwRange.upperBound...]
            .firstIndex(of: "{")
        else { cursor = structKwRange.upperBound; continue }

        // Text between struct name and `{` is the conformance list
        let conformance = String(source[structKwRange.upperBound..<structOpenBrace])
        guard isViewConformance(conformance) else {
            cursor = structOpenBrace
            continue
        }

        // Find the struct's closing `}`
        guard let structCloseBrace = matchingBrace(in: source, open: structOpenBrace) else {
            cursor = structOpenBrace
            continue
        }

        let structBodyRange = structOpenBrace..<structCloseBrace

        // ── 2. Find `var body: some View` inside this struct ─────────────
        guard let bodyVarRange = source.range(
            of: #"\bvar\s+body\s*:\s*some\s+View\b"#,
            options: .regularExpression,
            range: structBodyRange
        ) else { cursor = structCloseBrace; continue }

        // Find the `{` of the body implementation
        guard let bodyOpenBrace = source[bodyVarRange.upperBound..<structCloseBrace]
            .firstIndex(of: "{")
        else { cursor = structCloseBrace; continue }

        // Find its matching `}`
        guard let bodyCloseBrace = matchingBrace(in: source, open: bodyOpenBrace) else {
            cursor = structCloseBrace
            continue
        }

        // ── 3. Skip if already injected ───────────────────────────────────
        let existingBody = String(source[bodyOpenBrace...bodyCloseBrace])
        if existingBody.contains("_bttOriginalBody") || existingBody.contains("bttTrackScreen") {
            cursor = structCloseBrace
            continue
        }

        // ── 4. Skip if opted out ──────────────────────────────────────────
        if hasBTTIgnore(in: source, before: structKwRange.lowerBound) {
            cursor = structCloseBrace
            continue
        }

        return StructMatch(
            structName: structName,
            bodyVarRange: bodyVarRange,
            bodyOpenBrace: bodyOpenBrace,
            bodyCloseBrace: bodyCloseBrace
        )
    }

    return nil
}

// MARK: - Inject Into One Struct

func inject(into source: String, match: StructMatch) -> String {
    var result = source

    // The body content — everything between the outer { and }
    // e.g. "\n        VStack { Text(\"Ship\") }\n    "
    let bodyContent = String(
        result[result.index(after: match.bodyOpenBrace)..<match.bodyCloseBrace]
    )

    // Detect the indentation level of the `var body` line
    // so generated code lines up correctly
    let bodyIndent  = detectIndent(of: result, at: match.bodyVarRange.lowerBound)
    let innerIndent = bodyIndent + "    "

    // Build replacement:
    //
    //     @ViewBuilder
    //     private func _bttOriginalBody() -> some View {
    //         <original body content>
    //     }
    //
    //     var body: some View {
    //         _bttOriginalBody()
    //             .bttTrackScreen("ShipView")
    //     }
    //
    let replacement = """

    \(bodyIndent)@ViewBuilder
    \(bodyIndent)private var _bttOriginalBody: some View {\(bodyContent)}

    \(bodyIndent)var body: some View {
    \(innerIndent)_bttOriginalBody
    \(innerIndent)    .bttTrackScreen("\(match.structName)")
    \(bodyIndent)}
    """

    // Replace the entire `var body: some View { ... }` declaration
    let replaceStart = match.bodyVarRange.lowerBound
    let replaceEnd   = match.bodyCloseBrace

    result.replaceSubrange(replaceStart...replaceEnd, with: replacement)
    return result
}

// MARK: - Brace Matching

/// Returns the index of the `}` matching the `{` at `open`.
func matchingBrace(in source: String, open: String.Index) -> String.Index? {
    guard source[open] == "{" else { return nil }

    var depth          = 0
    var idx            = open
    var inLineComment  = false
    var inBlockComment = false
    var inString       = false
    var prevChar: Character = "\0"

    while idx < source.endIndex {
        let ch   = source[idx]
        let next = source.index(after: idx)

        // Block comment
        if !inString && !inLineComment && !inBlockComment
            && ch == "/" && next < source.endIndex && source[next] == "*" {
            inBlockComment = true
            prevChar = ch; idx = next; continue
        }
        if inBlockComment && prevChar == "*" && ch == "/" {
            inBlockComment = false
            prevChar = ch; idx = next; continue
        }
        if inBlockComment { prevChar = ch; idx = next; continue }

        // Line comment
        if !inString && ch == "/" && next < source.endIndex && source[next] == "/" {
            inLineComment = true
        }
        if inLineComment && ch == "\n" { inLineComment = false }
        if inLineComment { prevChar = ch; idx = next; continue }

        // String literal
        if ch == "\"" && prevChar != "\\" { inString.toggle() }
        if inString && ch != "\"" { prevChar = ch; idx = next; continue }

        // Brace counting
        if ch == "{" { depth += 1 }
        if ch == "}" {
            depth -= 1
            if depth == 0 { return idx }   // return index OF the closing brace
        }

        prevChar = ch
        idx = next
    }
    return nil
}

// MARK: - Helpers

func extractName(from structDecl: String) -> String {
    // "struct ShipView" → "ShipView"
    return structDecl
        .replacingOccurrences(of: "struct", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: CharacterSet.alphanumerics.union(.init(charactersIn: "_")).inverted)
        .first(where: { !$0.isEmpty }) ?? "UnknownScreen"
}

func isViewConformance(_ text: String) -> Bool {
    // Must contain bare `View` — not `ViewModifier`, not `SomeOtherView`
    let pattern = #"(?<![A-Za-z0-9_])View(?![A-Za-z0-9_])"#
    return text.range(of: pattern, options: .regularExpression) != nil
}

func hasBTTIgnore(in source: String, before idx: String.Index) -> Bool {
    let preceding = String(source[source.startIndex..<idx])
    return preceding
        .components(separatedBy: "\n")
        .suffix(3)
        .contains(where: { $0.contains("btt:ignore") })
}

/// Returns the leading whitespace of the line containing `idx`.
func detectIndent(of source: String, at idx: String.Index) -> String {
    // Walk backwards to find the start of the line
    var lineStart = idx
    while lineStart > source.startIndex {
        let prev = source.index(before: lineStart)
        if source[prev] == "\n" { break }
        lineStart = prev
    }
    // Count leading spaces/tabs
    var indent = ""
    var i = lineStart
    while i < idx {
        let ch = source[i]
        if ch == " " || ch == "\t" { indent.append(ch) } else { break }
        i = source.index(after: i)
    }
    return indent
}
