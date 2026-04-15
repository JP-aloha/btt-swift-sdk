//
//  main.swift
//  blue-triangle
//
//  Created by Ashok Singh on 10/04/26.
//

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

    // Skip if already macro injected anywhere
    if source.contains("@BTTTrackScreen") {
        print("⚠️ Already injected:", filePath)
        exit(0)
    }

    // Backup original
    if !FileManager.default.fileExists(atPath: backupPath) {
        try source.write(toFile: backupPath, atomically: true, encoding: .utf8)
    }

    // Step 1: Ensure import
    var rewritten = ensureImports(in: source)

    // Step 2: Inject macro on structs
    rewritten = injectAllMacros(into: rewritten)

    guard rewritten != source else {
        print("⏭ No changes needed:", filePath)
        exit(0)
    }

    try rewritten.write(toFile: filePath, atomically: true, encoding: .utf8)
    print("✅ Injected:", filePath)

} catch {
    print("❌ Error:", error)
    exit(1)
}

////////////////////////////////////////////////////////////
// MARK: - Inject Macro into All View Structs
////////////////////////////////////////////////////////////

func injectAllMacros(into source: String) -> String {
    var result = source
    var safetyLimit = 100

    while safetyLimit > 0 {
        safetyLimit -= 1
        guard let match = findNextInjectableViewStruct(in: result) else { break }
        result = injectMacro(into: result, match: match)
    }

    return result
}

////////////////////////////////////////////////////////////
// MARK: - Struct Detection
////////////////////////////////////////////////////////////

struct StructMatch {
    let structName: String
    let structKeywordRange: Range<String.Index>
}

func findNextInjectableViewStruct(in source: String) -> StructMatch? {
    var cursor = source.startIndex

    while cursor < source.endIndex {

        guard let structRange = source.range(
            of: #"\bstruct\s+([A-Za-z_][A-Za-z0-9_]*)"#,
            options: .regularExpression,
            range: cursor..<source.endIndex
        ) else { return nil }

        let structDecl = String(source[structRange])
        let structName = extractName(from: structDecl)

        // Find opening brace
        guard let openBrace = source[structRange.upperBound...].firstIndex(of: "{") else {
            cursor = structRange.upperBound
            continue
        }

        // Check conformance
        let conformance = String(source[structRange.upperBound..<openBrace])
        guard isViewConformance(conformance) else {
            cursor = openBrace
            continue
        }

        // Skip ignored
        if hasBTTIgnore(in: source, before: structRange.lowerBound) {
            cursor = openBrace
            continue
        }

        // Skip if macro already above struct
        let structLineStart = findLineStart(in: source, from: structRange.lowerBound)
        let previousLines = source[..<structLineStart]
            .split(separator: "\n")
            .suffix(3)

        if previousLines.contains(where: { $0.contains("@BTTTrackScreen") }) {
            cursor = openBrace
            continue
        }

        return StructMatch(
            structName: structName,
            structKeywordRange: structRange
        )
    }

    return nil
}

////////////////////////////////////////////////////////////
// MARK: - Inject Macro
////////////////////////////////////////////////////////////

func injectMacro(into source: String, match: StructMatch) -> String {
    var result = source

    let lineStart = findLineStart(in: result, from: match.structKeywordRange.lowerBound)
    let indent = detectIndent(of: result, at: lineStart)

    let macroLine = "\(indent)@BTTTrackScreen\n"

    result.insert(contentsOf: macroLine, at: lineStart)

    return result
}

////////////////////////////////////////////////////////////
// MARK: - Ensure Imports
////////////////////////////////////////////////////////////

func ensureImports(in source: String) -> String {
    var result = source

    guard result.contains("import SwiftUI") else { return result }

    if !result.contains("import BlueTriangle") {
        if let range = result.range(of: "import SwiftUI") {
            result.insert(contentsOf: "\nimport BlueTriangle", at: range.upperBound)
        }
    }

    return result
}

////////////////////////////////////////////////////////////
// MARK: - Helpers
////////////////////////////////////////////////////////////

func extractName(from structDecl: String) -> String {
    return structDecl
        .replacingOccurrences(of: "struct", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: CharacterSet.alphanumerics.union(.init(charactersIn: "_")).inverted)
        .first(where: { !$0.isEmpty }) ?? "UnknownScreen"
}

func isViewConformance(_ text: String) -> Bool {
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

func detectIndent(of source: String, at idx: String.Index) -> String {
    var lineStart = idx
    while lineStart > source.startIndex {
        let prev = source.index(before: lineStart)
        if source[prev] == "\n" { break }
        lineStart = prev
    }

    var indent = ""
    var i = lineStart
    while i < source.endIndex {
        let ch = source[i]
        if ch == " " || ch == "\t" {
            indent.append(ch)
            i = source.index(after: i)
        } else {
            break
        }
    }
    return indent
}

func findLineStart(in source: String, from index: String.Index) -> String.Index {
    var idx = index
    while idx > source.startIndex {
        let prev = source.index(before: idx)
        if source[prev] == "\n" { break }
        idx = prev
    }
    return idx
}
