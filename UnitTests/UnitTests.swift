//
//  UnitTests.swift
//  UnitTests
//
//  Created by Mohammad Rasoul Noori on 26/10/2024.
//

import Testing
import SwiftData
@testable import _dolist

struct UnitTests {
    var container: ModelContainer!
    
    @MainActor @Test func DeleteTask() {
        let context = container.mainContext
        
        let task = Task(task: "Simple Task", important: false)
       
        
        
    }
    
}
