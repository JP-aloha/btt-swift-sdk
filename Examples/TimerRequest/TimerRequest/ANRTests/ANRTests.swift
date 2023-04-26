//
//  ANRTests.swift
//  TimerRequest
//
//  Created by jaiprakash bokhare on 29/03/23.
//

import Foundation

//@_silgen_name("mach_backtrace")
//public func backtrace(_ thread: thread_t, stack: UnsafeMutablePointer<UnsafeMutableRawPointer?>!, _ maxSymbols: Int32) -> Int32
protocol Test{
    func test()->String
}

struct ANRTestFactory{
    
    //static var SleepMainThreadTest : Test {get { SleepMainThreadTest() } }
    //static var HeavyTaskTest : Test {get { SleepMainThreadTest() } }
    //static var HeavyDownloadTest : Test {get { SleepMainThreadTest() } }
}

struct SleepMainThreadTest : Test{
    
    func test() -> String {
        DispatchQueue.main.async {
            Thread.sleep(forTimeInterval: 10)
        }
        return "MainThread will be sleep for 10 Sec."
    }
}

struct HeavyTaskTest : Test{
    
    func test() -> String {
        DispatchQueue.main.async {
            Thread.sleep(forTimeInterval: 10)
        }
        return "MainThread will be sleep for 10 Sec."
    }
}

func printMainThreadStack(){
    
}

//@_silgen_name("get_backtrace")
//public func backtrace(_ thread: thread_t,  count: UnsafePointer<Int>) -> UnsafeMutablePointer<UnsafeMutableRawPointer?>!
////https://github.com/apple/swift-evolution/blob/main/proposals/0262-demangle.md
//
//@_silgen_name("swift_demangle")
//public
//func _stdlib_demangleImpl(
//    mangledName: UnsafePointer<CChar>?,
//    mangledNameLength: UInt,
//    outputBuffer: UnsafeMutablePointer<CChar>?,
//    outputBufferSize: UnsafeMutablePointer<UInt>?,
//    flags: UInt32
//    ) -> UnsafeMutablePointer<CChar>?
//
//public func _stdlib_demangleName(_ mangledName: String) -> String {
//    return mangledName.utf8CString.withUnsafeBufferPointer {
//        (mangledNameUTF8CStr) in
//
//        let demangledNamePtr = _stdlib_demangleImpl(
//            mangledName: mangledNameUTF8CStr.baseAddress,
//            mangledNameLength: UInt(mangledNameUTF8CStr.count - 1),
//            outputBuffer: nil,
//            outputBufferSize: nil,
//            flags: 0)
//
//        if let demangledNamePtr = demangledNamePtr {
//            let demangledName = String(cString: demangledNamePtr)
//            free(demangledNamePtr)
//            return demangledName
//        }
//        return mangledName
//    }
//}

//
//var mainThreadRef : thread_t?
//
//func getMainThreadRef() throws/*-> thread_t*/{
//
//    mainThreadRef = mach_thread_self()
//
//
//    guard let mainThread = mainThreadRef else{
//        throw NSError(domain: "MainThread Trace", code: 1)
//    }
//
//
//    var count : Int = 0
//    var trace = backtrace(mainThread, count: &count)
//    var traceLines : [String] = []
//
//    print("Received Trace \(trace) count : \(count)")
//
//    let buf = UnsafeBufferPointer(start: trace, count: count)
//
//    for (index, addr) in buf.enumerated() {
//        guard let addr = addr else { continue }
//        let addrValue = UInt(bitPattern: addr)
//
//        var info = dl_info()
//        dladdr(UnsafeRawPointer(bitPattern: addrValue), &info)
//        print("---")
//        print("stack ::\(addrValue)")
//
//        var module = ""
//        var function = ""
//        var line = 0
//
//        var file = String(cString: info.dli_fname)
//        print("File : \(file)")
//        if let url = NSURL(fileURLWithPath: file).lastPathComponent{
//            module = url
//        }else{ module = file}
//
//        if let dli_sname = info.dli_sname, let sname = String(validatingUTF8: dli_sname) {
//            print("Symbol : \(sname) :: \(_stdlib_demangleName(sname))")
//
//           line =  Int(addrValue - UInt(bitPattern: info.dli_saddr))
//            print("Offset : \(line)")
//
//            function = _stdlib_demangleName(sname)
//        }
//
//        traceLines.append("\(module) :: \(function)@\(line)")
//        //let symbol = StackSymbolFactory.create(address: addrValue, index: index)
//        //symbols.append(symbol)
//    }
//
//    let result = traceLines.reduce("") { partialResult, line in
//        return "\(partialResult)\n \(line)"
//    }
//
//    print("---FinalTrace---")
//    print(result)
////    _STRUCT_MCONTEXT machineContext;
////    mach_msg_type_number_t stateCount = THREAD_STATE_COUNT;
////
////    kern_return_t kret = thread_get_state(thread, THREAD_STATE_FLAVOR, (thread_state_t)&(machineContext.__ss), &stateCount);
////    if (kret != KERN_SUCCESS) {
////        return 0;
////    }
////
////
////
////
////
////
////    let stackSize: UInt32 = 128
////    let addrs = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: Int(stackSize))
////    let frameCount = backtrace(mainThread, stack: addrs, Int32(stackSize))
////
////    print("FrameCount \(frameCount)")
////
////    let buf = UnsafeBufferPointer(start: addrs, count: Int(frameCount))
////    print("Trace")
////    for (index, addr) in buf.enumerated() {
////        guard let addr = addr else { continue }
////        let addrValue = UInt(bitPattern: addr)
////        print("\(addrValue)")
////        //let symbol = StackSymbolFactory.create(address: addrValue, index: index)
////        //symbols.append(symbol)
////    }
////
//
//    //get threads count
////    var allThreadsCount: mach_msg_type_number_t = 0
////    var allThreads: thread_act_array_t!
////
////    if task_threads(mach_task_self_, &(allThreads), &allThreadsCount) != KERN_SUCCESS{
////        throw NSError(domain: "MainThread Trace", code: 1)
////    }
////
////    print("Count \(allThreadsCount) : AllThreads \(String(describing: allThreads))")
////    print("MainThreadName = \(Thread.main.name)")
////    for index in 0..<allThreadsCount {
////        //let index = Int(i)
////
////        if let pThread = pthread_from_mach_thread_np(allThreads[Int(index)]) {
////            //char name[256];
////            //name[0] = '\0';
////            //int rc = pthread_getname_np(pt, name, sizeof name);
////
////            var threadName: [Int8] = [Int8]()
////            threadName.append(Int8(Character.init("\0").asciiValue!))
////            pthread_getname_np(pThread, &threadName, MemoryLayout<Int8>.size * 256)
////
////            print("\(threadName)")
////
//////            if (strcmp(&name, (thread.name!.ascii)) == 0) {
//////                thread.name = originName
//////                return threads[index]
//////            }
////        }
////    }
//
//    print("--End--")
//}
