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
    
    

    @MainActor
    func testMarkAsComplete() throws {
        let context = container.mainContext
        
        // Fetch all tasks and delete them for a clean slate
        let fetchDescriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(fetchDescriptor)
        
        // Delete each task
        for task in tasks {
            context.delete(task)
        }
        
        // Save the context to persist the deletions
        try context.save()

        // Arrange: Create a new task and insert it into the context
        let task = _dolist.Task(task: "Task to complete", important: false)
        context.insert(task)
        try context.save()

        // Act: Create TaskView and simulate the completion
        let taskView = TaskView(task: task)
        taskView.markAsComplete()
        
        // Expectation to wait for the 1.5-second delay in `markAsComplete()`
        let expectation = XCTestExpectation(description: "Wait for task to be deleted after markAsComplete")
        
        // Wait for 2 seconds to ensure the task is deleted after the delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 3)
        
        // Fetch the tasks from the context again to verify deletion
        
        // Assert: The task should be deleted, so tasks.count should be 0
        XCTAssertEqual(tasks.count, 0, "The task should be deleted after marking it as complete.")
    }

    
}
