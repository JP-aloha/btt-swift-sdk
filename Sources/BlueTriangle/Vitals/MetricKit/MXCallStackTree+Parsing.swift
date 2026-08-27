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
        let name = binaryName ?? "???"
        let addressHex = String(format: "0x%016llx", address ?? 0)
        let offset = offsetIntoBinaryTextSegment ?? 0
        return "\(index)   \(name.paddedToColumn(binaryNameColumnWidth))\(addressHex) \(name) + \(offset)"
    }
}

private let binaryNameColumnWidth = 31

private extension String {
    func paddedToColumn(_ width: Int) -> String {
        count >= width ? self : self + String(repeating: " ", count: width - count)
    }
}
#endif
