//
//  MemoryAllocationTest.swift
//
//  Created by JP on 30/08/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

class MemoryAllocationTest {

    private var allocatedMemoryBlocks: [UnsafeMutableRawPointer] = []
    
    private func allocateMemory(_ size : Int) {
        
        let totalSize: Int = size * 1024 * 1024   //size MB
        
        guard let memoryBlock = malloc(totalSize) else{
            print("Memory allocation failed.")
            return
        }
 
        let data = "H".data(using: .utf8)! as NSData
        memcpy(memoryBlock, data.bytes, totalSize)
        allocatedMemoryBlocks.append(memoryBlock)
        
        print("allocated memory \(size) MB")
    }
    
    private func freeOneBlockMemory() {
    
       if let block = allocatedMemoryBlocks.first {
            free(block)
            allocatedMemoryBlocks.remove(at: 0)
        }
    }
    
    private func deallocateMemory() {
        
        for block in allocatedMemoryBlocks {
            free(block)
        }
       
        allocatedMemoryBlocks.removeAll()
        print("Free allocated memory")
    }
    
    deinit {
        deallocateMemory()
    }
}

extension MemoryAllocationTest{
   
    func runMemoryTest() {
        self.allocateMemory(100)
    }
    
    func freeAllMemoryTest() {
        self.deallocateMemory()
    }
    
    func freeBlockMemory(){
        freeOneBlockMemory()
    }
}

