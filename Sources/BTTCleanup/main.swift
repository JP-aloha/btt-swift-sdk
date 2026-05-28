//
//  main.swift
//  blue-triangle
//
//  Created by Ashok Singh on 26/05/26.
//

#if os(macOS)
import Foundation

//swift run BTTSetup       # sets up BlueTriangle in the app project
//swift run BTTCleanup     # removes everything BTTSetup added
//swift run BTTCleanup --dry-run    # preview what would be removed
//swift run BTTCleanup --scripts-only   # only delete the shell scripts
//swift run BTTCleanup --phases-only    # only remove the Xcode build phases

// MARK: - ANSI Colors

enum C {
    static let reset  = "\u{001B}[0m"
    static let bold   = "\u{001B}[1m"
    static let green  = "\u{001B}[0;32m"
    static let yellow = "\u{001B}[1;33m"
    static let red    = "\u{001B}[0;31m"
    static let blue   = "\u{001B}[0;34m"
    static let cyan   = "\u{001B}[0;36m"
}

func step(_ msg: String)  { print("\n\(C.bold)\(C.blue)▶ \(msg)\(C.reset)") }
func ok(_ msg: String)    { print("  \(C.green)✅ \(msg)\(C.reset)") }
func warn(_ msg: String)  { print("  \(C.yellow)⚠️  \(msg)\(C.reset)") }
func info(_ msg: String)  { print("  \(C.cyan)ℹ️  \(msg)\(C.reset)") }
func dry(_ msg: String)   { print("  \(C.yellow)[DRY-RUN] \(msg)\(C.reset)") }
func fail(_ msg: String)  { print("  \(C.red)❌ \(msg)\(C.reset)") }

// MARK: - Helpers

let fm = FileManager.default

func findXcodeproj(in root: String) -> String? {
    guard let enumerator = fm.enumerator(
        at: URL(fileURLWithPath: root),
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
    ) else { return nil }

    for case let url as URL in enumerator {
        let depth = url.pathComponents.count - URL(fileURLWithPath: root).pathComponents.count
        if depth > 4 { enumerator.skipDescendants(); continue }
        if url.pathExtension == "xcodeproj" { return url.path }
    }
    return nil
}

@discardableResult
func shell(_ args: [String]) -> Int32 {
    let task = Process()
    task.launchPath = args[0]
    task.arguments  = Array(args.dropFirst())
    try? task.run()
    task.waitUntilExit()
    return task.terminationStatus
}

// MARK: - Ruby script — removes BTT phases from .xcodeproj

let rubyScript = #"""
require 'xcodeproj'

proj_path    = ARGV[0]
inject_name  = ARGV[1]
restore_name = ARGV[2]

project  = Xcodeproj::Project.open(proj_path)
modified = false

project.targets.each do |target|
  next unless target.is_a?(Xcodeproj::Project::Object::PBXNativeTarget)
  next unless target.product_type == "com.apple.product-type.application"

  to_remove = target.build_phases.select { |p|
    [inject_name, restore_name].include?(p.display_name)
  }

  to_remove.each do |phase|
    target.build_phases.delete(phase)
    puts "  ✅ Removed '#{phase.display_name}' from #{target.name}"
    modified = true
  end

  if to_remove.empty?
    puts "  ℹ️  No BTT phases found in #{target.name}"
  end
end

if modified
  project.save
  puts "\n  💾 Project saved."
else
  puts "\n  ℹ️  Nothing to remove — project unchanged."
end
"""#

// MARK: - Main

func printHelp() {
    print("""
\(C.bold)BTTCleanup — Remove BlueTriangle SDK setup\(C.reset)

\(C.bold)USAGE\(C.reset)
  swift run BTTCleanup [path] [options]

\(C.bold)ARGUMENTS\(C.reset)
  path            Path to the app project root (default: current directory)

\(C.bold)OPTIONS\(C.reset)
  --dry-run       Preview what would be removed, make no changes
  --phases-only   Only remove Xcode build phases, keep Scripts/
  --scripts-only  Only delete Scripts/btt-*.sh, keep Xcode phases
  --help, -h      Show this message

\(C.bold)EXAMPLES\(C.reset)
  swift run BTTCleanup
  swift run BTTCleanup ~/MyApp
  swift run BTTCleanup --dry-run
""")
}

func run() {
    // ── Parse args ────────────────────────────────────────────────
    var dryRun      = false
    var doScripts   = true
    var doPhases    = true
    var projectRoot = ""

    for arg in CommandLine.arguments.dropFirst() {
        switch arg {
        case "--dry-run":      dryRun = true
        case "--phases-only":  doScripts = false
        case "--scripts-only": doPhases = false
        case "--help", "-h":   printHelp(); exit(0)
        default:
            if !arg.hasPrefix("--") && projectRoot.isEmpty {
                projectRoot = arg
            }
        }
    }

    if projectRoot.isEmpty { projectRoot = fm.currentDirectoryPath }
    if projectRoot.hasPrefix("~") {
        projectRoot = NSHomeDirectory() + projectRoot.dropFirst()
    }

    // ── Banner ────────────────────────────────────────────────────
    print("")
    print("\(C.bold)╔══════════════════════════════════════════╗\(C.reset)")
    print("\(C.bold)║    BlueTriangle SDK  ·  BTTCleanup       ║\(C.reset)")
    print("\(C.bold)╚══════════════════════════════════════════╝\(C.reset)")
    print("")
    info("Project root : \(projectRoot)")
    info("Dry run      : \(dryRun)")
    info("Remove scripts : \(doScripts)")
    info("Remove phases  : \(doPhases)")

    // ── Step 1: Delete Scripts/ ───────────────────────────────────
    if doScripts {
        step("Removing injection scripts...")

        let scriptsDir  = (projectRoot as NSString).appendingPathComponent("Scripts")
        let injectPath  = (scriptsDir as NSString).appendingPathComponent("btt-inject.sh")
        let restorePath = (scriptsDir as NSString).appendingPathComponent("btt-restore.sh")

        for path in [injectPath, restorePath] {
            if fm.fileExists(atPath: path) {
                if dryRun {
                    dry("Would delete: \(path)")
                } else {
                    do {
                        try fm.removeItem(atPath: path)
                        ok("Deleted: \((path as NSString).lastPathComponent)")
                    } catch {
                        fail("Could not delete \(path): \(error.localizedDescription)")
                    }
                }
            } else {
                info("Not found (skipping): \((path as NSString).lastPathComponent)")
            }
        }

        // Remove Scripts/ dir if now empty
        if !dryRun,
           let contents = try? fm.contentsOfDirectory(atPath: scriptsDir),
           contents.isEmpty {
            try? fm.removeItem(atPath: scriptsDir)
            ok("Removed empty Scripts/ directory")
        }
    }

    // ── Step 2: Find .xcodeproj ───────────────────────────────────
    guard doPhases else {
        printDone(dryRun: dryRun)
        return
    }

    step("Locating Xcode project...")

    guard let xcodeproj = findXcodeproj(in: projectRoot) else {
        fail("No .xcodeproj found under \(projectRoot)")
        exit(1)
    }
    ok("Found: \(xcodeproj)")

    // ── Step 3: Remove build phases via Ruby ──────────────────────
    step("Removing Xcode Run Script build phases...")

    if dryRun {
        dry("Would remove 'BTT Inject' from all app targets")
        dry("Would remove 'BTT Restore' from all app targets")
        dry("Would save \(xcodeproj)")
    } else {
        let tmpRuby = NSTemporaryDirectory() + "btt_cleanup.rb"
        try? rubyScript.write(toFile: tmpRuby, atomically: true, encoding: .utf8)

        let result = shell([
            "/usr/bin/ruby", tmpRuby,
            xcodeproj,
            "BTT Inject",
            "BTT Restore"
        ])

        try? fm.removeItem(atPath: tmpRuby)

        if result != 0 {
            fail("Ruby script failed (exit \(result))")
            info("You can remove the phases manually in Xcode → target → Build Phases")
            exit(1)
        }
    }

    printDone(dryRun: dryRun)
}

func printDone(dryRun: Bool) {
    print("")
    print("\(C.bold)\(C.green)╔══════════════════════════════════════════╗\(C.reset)")
    print("\(C.bold)\(C.green)║         Cleanup Complete 🧹               ║\(C.reset)")
    print("\(C.bold)\(C.green)╚══════════════════════════════════════════╝\(C.reset)")
    print("")

    if dryRun {
        warn("Dry-run — no changes were made.")
    } else {
        print("  \(C.green)BlueTriangle setup has been removed:\(C.reset)")
        print("")
        print("  1. \(C.bold)Scripts/btt-inject.sh\(C.reset)  deleted")
        print("  2. \(C.bold)Scripts/btt-restore.sh\(C.reset) deleted")
        print("  3. \(C.bold)BTT Inject\(C.reset) build phase removed")
        print("  4. \(C.bold)BTT Restore\(C.reset) build phase removed")
        print("")
        print("  \(C.cyan)Your source files are untouched.\(C.reset)")
    }
    print("")
}

run()

#else
@_silgen_name("main") func main() {}
#endif
