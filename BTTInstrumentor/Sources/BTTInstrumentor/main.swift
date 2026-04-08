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
    }

    exit(0)
}

// MARK: - INJECT

do {
    var source = try String(contentsOfFile: filePath)

    guard source.contains("import SwiftUI") else { exit(0) }

    if source.contains(".bttTrackScreen") {
        print("⚠️ Already injected")
        exit(0)
    }

    // Backup
    if !FileManager.default.fileExists(atPath: backupPath) {
        try source.write(toFile: backupPath, atomically: true, encoding: .utf8)
    }

    let structName = extractStructName(from: source) ?? "UnknownScreen"

    guard let bodyRange = source.range(of: "var body: some View") else {
        exit(0)
    }

    guard let openBrace = source[bodyRange.upperBound...].firstIndex(of: "{") else {
        exit(0)
    }

    // Find matching closing brace
    var braceCount = 0
    var closeIndex: String.Index?

    for index in source[openBrace...].indices {
        if source[index] == "{" {
            braceCount += 1
        } else if source[index] == "}" {
            braceCount -= 1
            if braceCount == 0 {
                closeIndex = index
                break
            }
        }
    }

    guard let endIndex = closeIndex else {
        print("❌ Could not find body end")
        exit(0)
    }

    // Extract body content
    let bodyContent = source[source.index(after: openBrace)..<endIndex]

    // 🔥 Wrap in Group
    let newBody = """
    {
        Group {
    \(bodyContent)
        }
        .bttTrackScreen("\(structName)")
    }
    """

    // Replace body
    source.replaceSubrange(openBrace...endIndex, with: newBody)

    try source.write(toFile: filePath, atomically: true, encoding: .utf8)

    print("✅ Injected (universal):", structName)

} catch {
    print("❌ Error:", error)
}

// MARK: - Helper
func extractStructName(from source: String) -> String? {
    let regex = try? NSRegularExpression(pattern: #"struct\s+(\w+)\s*:\s*View"#)
    let range = NSRange(source.startIndex..., in: source)

    if let match = regex?.firstMatch(in: source, range: range),
       let nameRange = Range(match.range(at: 1), in: source) {
        return String(source[nameRange])
    }
    return nil
}
