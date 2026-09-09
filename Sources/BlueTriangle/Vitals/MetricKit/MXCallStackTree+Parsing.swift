//
//  MXCallStackTree+Parsing.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

#if os(iOS)
import Foundation

struct MXCallStackTreeJSON: Decodable {
    let callStacks: [CallStack]

    struct CallStack: Decodable {
        let threadAttributed: Bool?
        let callStackRootFrames: [Frame]
    }

    struct Frame: Decodable {
        let binaryName: String?
        let binaryUUID: String?
        let address: UInt64?
        let offsetIntoBinaryTextSegment: Int?
        let subFrames: [Frame]?
    }
}

extension MXCallStackTreeJSON {
    static func decode(from data: Data) -> MXCallStackTreeJSON? {
        try? JSONDecoder().decode(MXCallStackTreeJSON.self, from: data)
    }


    func formattedStackTrace() -> String? {
        guard !callStacks.isEmpty else { return nil }
        var lines = [String]()
        for (index, callStack) in callStacks.enumerated() {
            let attributed = callStack.threadAttributed == true ? " Crashed" : ""
            lines.append("Thread \(index)\(attributed):")
            let frames = callStack.callStackRootFrames.flatMap { $0.flattenedDeepestFirst() }
            for (frameIndex, frame) in frames.enumerated() {
                lines.append(frame.formattedFrameLine(index: frameIndex))
            }
        }
        return lines.joined(separator: "\n")
    }

    func crashedThreadFrame(preferringBinaryNamed appBinaryName: String?) -> Frame? {
        let stack = callStacks.first(where: { $0.threadAttributed == true }) ?? callStacks.first
        guard var frame = stack?.callStackRootFrames.first else { return nil }

        var chain = [frame]
        while let next = frame.subFrames?.first {
            chain.append(next)
            frame = next
        }

        if let appBinaryName, let appFrame = chain.reversed().first(where: { $0.binaryName == appBinaryName }) {
            return appFrame
        }
        return chain.last
    }
}

extension MXCallStackTreeJSON.Frame {
    func formattedCrashLocation() -> String {
        let name = binaryName ?? "???"
        let addressHex = String(format: "0x%016llx", address ?? 0)
        let offset = offsetIntoBinaryTextSegment ?? 0
        return "\(name.paddedToColumn(binaryNameColumnWidth))\(addressHex) \(name) + \(offset)"
    }
}

private extension MXCallStackTreeJSON.Frame {
    func flattenedDeepestFirst() -> [MXCallStackTreeJSON.Frame] {
        (subFrames ?? []).flatMap { $0.flattenedDeepestFirst() } + [self]
    }

    func formattedFrameLine(index: Int) -> String {
        "\(index)   \(formattedFrameLineWithoutIndex())"
    }

    /// Same line, without the leading frame index - for the structured stack trace's `fLine`,
    /// where the index is already its own `i` field and repeating it would be redundant.
    func formattedFrameLineWithoutIndex() -> String {
        let name = binaryName ?? "???"
        let addressHex = String(format: "0x%016llx", address ?? 0)
        let offset = offsetIntoBinaryTextSegment ?? 0
        return "\(name.paddedToColumn(binaryNameColumnWidth))\(addressHex) \(name) + \(offset)"
    }
}

private let binaryNameColumnWidth = 31

private extension String {
    func paddedToColumn(_ width: Int) -> String {
        count >= width ? self : self + String(repeating: " ", count: width - count)
    }
}

// MARK: - Structured (JSON) stack trace, for crash diagnostics only

/// Minimal, versioned shape (meta + per-thread frame stacks) so `stackTrace` can carry a parseable
/// JSON string instead of the flattened plain-text format `formattedStackTrace()` produces. Deliberately
/// carries only what isn't already available elsewhere in the payload or derivable from `fLine`
/// itself (binary name/address/offset are embedded in `fLine`'s text) - just enough to identify the
/// format (`fVersion`), the thread, and each frame's binary UUID for symbolication.
struct CrashStackTraceReport: Encodable {
    struct Meta: Encodable {
        let fVersion: String
    }

    struct Frame: Encodable {
        let i: Int
        let bId: String?
        let fLine: String
    }

    struct Thread: Encodable {
        let id: String
        let name: String
        let crashed: Bool
        let stack: [Frame]
    }

    let meta: Meta
    let threads: [Thread]
}

private let stackTraceFormatVersion = "1.0.0"

extension MXCallStackTreeJSON {
    /// Builds the structured crash report and returns it JSON-encoded as a string, or nil if there
    /// are no call stacks to report (matching `formattedStackTrace()`'s own nil-when-empty behavior).
    func buildStructuredStackTrace() -> String? {
        guard !callStacks.isEmpty else { return nil }

        let threads: [CrashStackTraceReport.Thread] = callStacks.enumerated().map { index, callStack in
            let isCrashed = callStack.threadAttributed == true
            let frames = callStack.callStackRootFrames.flatMap { $0.flattenedDeepestFirst() }

            let stack: [CrashStackTraceReport.Frame] = frames.enumerated().map { frameIndex, frame in
                CrashStackTraceReport.Frame(
                    i: frameIndex,
                    bId: frame.binaryUUID,
                    fLine: frame.formattedFrameLineWithoutIndex())
            }

            return CrashStackTraceReport.Thread(
                id: "\(index)",
                name: isCrashed ? "Main Thread" : "Thread \(index)",
                crashed: isCrashed,
                stack: stack)
        }

        let report = CrashStackTraceReport(meta: .init(fVersion: stackTraceFormatVersion), threads: threads)
        guard let data = try? JSONEncoder().encode(report),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return json
    }
}
#endif
