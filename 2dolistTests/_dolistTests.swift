//
//  _dolistTests.swift
//  2dolistTests
//
//  Created by Mohammad Rasoul Noori on 14/9/2024.
//

import XCTest
import SwiftData
@testable import _dolist

final class _dolistTests: XCTestCase {
    
    var container: ModelContainer!
    
    override func setUp() {
        super.setUp()
        
        // Initialize the container with your Task model
        container = try! ModelContainer(for: Task.self)
    }
    
    

   
    
}
