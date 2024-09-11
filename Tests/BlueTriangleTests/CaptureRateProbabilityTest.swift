//
//  CaptureRateProbabilityTest.swift
//  
//
//  Created by Ashok Singh on 10/09/24.
//

import XCTest
@testable import BlueTriangle

final class CaptureRateProbabilityTest: XCTestCase {

    func testShouldCaptureRequestsProbability() {
        
        let testCases: [(givenProbability: Double, expectedMinProbability: Double, expectedMaxProbability: Double)] = [
            (75, 65, 85), // 70% - 90%
            (50, 40, 60), // 40% - 60%
            (25, 15, 35)  // 15% - 35%
        ]
        
        let totalSamples = 100
        let iterations = 5
        
        for iteration in 1...iterations{
            
            print("****Iteration : \(iteration) *** sample----------------------------------------------------------------**")
            
            for testCase in testCases {
                var trueCount = 0
                let givenProbability = testCase.givenProbability / 100.0
                
                for _ in 1...totalSamples {
                    if Bool.random(probability: givenProbability) {
                        trueCount += 1
                    }
                }
                
                let actualTrueRatio = Double(trueCount)
                
                print("Test with given probability \(testCase.givenProbability)% with the actual result observed was  \(actualTrueRatio)% from a sample of \(totalSamples). Expected between \(testCase.expectedMinProbability)% and \(testCase.expectedMaxProbability)%")
                
                XCTAssertTrue(actualTrueRatio >= testCase.expectedMinProbability && actualTrueRatio <= testCase.expectedMaxProbability, "Test failed for probability \(testCase.givenProbability)% with the actual result observed was \(actualTrueRatio)% from a sample of \(totalSamples). Expected between \(testCase.expectedMinProbability)% and \(testCase.expectedMaxProbability)%")
            }
        }
    }
}
