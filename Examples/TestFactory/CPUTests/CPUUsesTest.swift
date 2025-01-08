//
//  CPUUsesTest.swift
//
//  Created by JP on 14/09/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

class CPUUsesTest {
    
    func runSingleCoreFiftyToEightyPercent(){
        DispatchQueue.global().async {
            let extractTaskCombination = AlphabetCombination()
             extractTaskCombination.cpuUses50_80Percent()
        }
    }
    
    func runSingleCoreHundradePercent(){
        
        DispatchQueue.global().async {
            let extractTaskCombination = AlphabetCombination()
            extractTaskCombination.runInfiniteLoop()
        }
    }
    
    func runDoubleCoreHundradePercent(){
       
        DispatchQueue.global().async {
            let extractTaskCombination = AlphabetCombination()
            extractTaskCombination.runInfiniteLoop()
        }
        
        DispatchQueue.global().async {
            let extractCombination = AlphabetCombination()
            extractCombination.runInfiniteLoop()
        }
    }
}


class AlphabetCombination{
    
    var result: [String] = []
    let idleTime : CGFloat = 30
    
    
    func cpuUses50_80Percent(){
        
        let startTime = Date()
        var counter = 0
        
        while true {
           
            counter = counter  + 1
            
            if (Date().timeIntervalSince1970 - startTime.timeIntervalSince1970) < idleTime {
           
                NSLog("BlueTriangle Counter:\(counter)")
                if counter % 20000000 == 0{
                    Thread.sleep(forTimeInterval: 1)
                    print("Sleep 1")
                    print("Processer : \(ProcessInfo.processInfo.activeProcessorCount)")
                }
                
                NSLog("BlueTriangle  CPU Usage:  Counter :\(counter)")
                if counter % 10000000 == 0{
                    Thread.sleep(forTimeInterval: 1)
                    print("Sleep 2")
                    print("Processer : \(ProcessInfo.processInfo.activeProcessorCount)")
                }
            }else{
                print("Break")
                break;
            }
        }
    }
    
    func runInfiniteLoop(){
        
        let startTime = Date()
        
        while true {
            if (Date().timeIntervalSince1970 - startTime.timeIntervalSince1970) > idleTime {
                break
            }
        }
    }
    
    func makeAllCombinations() -> [String] {
         
         result.removeAll()

         let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
         let n = alphabet.count
         let desChar =  "unknwon"
         let startTime = Date()

         for length in 0..<desChar.count {
             
             for i in 0..<n {
                 
                 if (Date().timeIntervalSince1970 - startTime.timeIntervalSince1970) > idleTime {
                     return []
                 }
                 
                 makeCombination(alphabet, n, length, "\(alphabet[i])")
                 
             }
         }

         return result
     }
     
     private func makeCombination(_ alphabet: [Character], _ n: Int, _ length: Int, _ currentString: String) {
        
         if length == 0 {
             result.append(currentString)
             return
         }

         for i in 0..<n {
             let newString = currentString + String(alphabet[i])
             makeCombination(alphabet, n, length - 1, newString)
         }
     }
}
