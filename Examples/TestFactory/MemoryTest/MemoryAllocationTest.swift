import Foundation

class MemoryAllocationTest {

    private var allocatedMemoryBlocks: [UnsafeMutableRawPointer] = []
    
    private func allocateMemory(_ size : Int) {
        
        let totalSize: Int = size * 1024 * 1024   //size MB
        
        guard let memoryBlock = malloc(totalSize) else{
            print("Memory allocation failed.")
            return
        }
        
        memset(memoryBlock, 0, totalSize)
        
        allocatedMemoryBlocks.append(memoryBlock)
        
       /* let totalMB = allocatedMemoryBlocks.count * size
        
        if totalMB <= 1024 {
            print("Total allocated memory : \(totalMB) MB")
        }else{
            print("Total allocated memory : \(totalMB / 1024) GB \(totalMB % 1024) MB")
        }*/
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
    
    func runLightMemoryTest() {
        self.allocateMemory(1)
    }
}
