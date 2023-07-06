//
//  MainThreadStackTraceProvider.swift
//  TimerRequest
//
//  Created by JP on 22/04/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

@_silgen_name("get_backtrace") //link with implementation from backtrace_extractor.c
public func backtrace(_ thread: thread_t,  count: UnsafePointer<Int>) -> UnsafeMutablePointer<UnsafeMutableRawPointer?>!

//https://github.com/apple/swift-evolution/blob/main/proposals/0262-demangle.md
@_silgen_name("swift_demangle") //not implemented in this code link with library private implementation
public
func _stdlib_demangleImpl(
    mangledName: UnsafePointer<CChar>?,
    mangledNameLength: UInt,
    outputBuffer: UnsafeMutablePointer<CChar>?,
    outputBufferSize: UnsafeMutablePointer<UInt>?,
    flags: UInt32
    ) -> UnsafeMutablePointer<CChar>?

public func _stdlib_demangleName(_ mangledName: String) -> String {
    return mangledName.utf8CString.withUnsafeBufferPointer {
        (mangledNameUTF8CStr) in

        let demangledNamePtr = _stdlib_demangleImpl(
            mangledName: mangledNameUTF8CStr.baseAddress,
            mangledNameLength: UInt(mangledNameUTF8CStr.count - 1),
            outputBuffer: nil,
            outputBufferSize: nil,
            flags: 0)

        if let demangledNamePtr = demangledNamePtr {
            let demangledName = String(cString: demangledNamePtr)
            free(demangledNamePtr)
            return demangledName
        }
        return mangledName
    }
}

class MainThreadTraceProvider{
    private var mainThreadRef : thread_t?
    private var anrStackTrace: Bool = true
    
    static let shared = MainThreadTraceProvider()
    
    func setup(){
        DispatchQueue.main.async {
            self.mainThreadRef = mach_thread_self()
        }
    }
    
    func setUpStackTrace(_ trace : Bool){
        self.anrStackTrace = trace
    }
    
    func getTrace() throws -> String{
        
        guard let mainThread = mainThreadRef else{
            throw NSError(domain: "MainThreadTraceProvider", code: 0)
        }
        
        if !self.anrStackTrace {
            return ""
        }
        
        var count : Int = 0
        var trace = backtrace(mainThread, count: &count)
        var traceLines : [String] = []
        
        //print("Received Trace \(trace) count : \(count)")
        
        let buf = UnsafeBufferPointer(start: trace, count: count)

        for (index, addr) in buf.enumerated() {
            guard let addr = addr else { continue }
            let addrValue = UInt(bitPattern: addr)
            
            var info = dl_info()
            dladdr(UnsafeRawPointer(bitPattern: addrValue), &info)
            //print("---")
            //print("stack ::\(addrValue)")
            
            var module = ""
            var function = ""
            var line = 0
            
            var file = String(cString: info.dli_fname)
            //print("File : \(file)")
            if let url = NSURL(fileURLWithPath: file).lastPathComponent{
                module = url
            }else{ module = file}
            
            if let dli_sname = info.dli_sname, let sname = String(validatingUTF8: dli_sname) {
                //print("Symbol : \(sname) :: \(_stdlib_demangleName(sname))")
            
               line =  Int(addrValue - UInt(bitPattern: info.dli_saddr))
                //print("Offset : \(line)")
                
                function = _stdlib_demangleName(sname)
            }
            
            traceLines.append("\(module) :: \(function)@\(line)")
        }
        
        let result = traceLines.reduce("") { partialResult, line in
            return "\(partialResult)\n \(line)"
        }
        
        return result
    }
}
