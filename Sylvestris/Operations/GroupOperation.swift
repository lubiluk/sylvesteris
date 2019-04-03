//
//  GroupOperation.swift
//
//  Copyright (c) 2018 Paweł Gajewski
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/**
 A subclass of Operation for performing a group of tasks.
 This class is intended to be subclassed, not used directly.
 
 - Note: This operation is done when all sub operations are done.
         There is nothing that happens outside of any operation.
 */
class GroupOperation: AsyncOperation {
    lazy var queue: OperationQueue = {
        var queue = OperationQueue()
        
        queue.name = "\(String(describing: self)) queue"
        queue.isSuspended = true
        
        return queue
    }()
    
    private var operationObservation : NSKeyValueObservation?
    
    var errorAggregate = ErrorAggregate()
    
    final override func operationDidStart() {
        operationQueueWillBeginExecution(queue: self.queue)
        
        if queue.operationCount == 0 {
            finish()
            return
        }
        
        // Retrieve errors from sub-operations when they finish.
        // Finish when all sub-operations finish.
        operationObservation = queue.observe(\.operations, options: [.old, .new]) { [unowned self] (queue, change) in
            let oldOperations = Set(change.oldValue!)
            let newOperations = Set(change.newValue!)
            let removedOperations = oldOperations.subtracting(newOperations)
            
            for operation in removedOperations {
                if let resultOperation = operation as? ResultOperation, let error = resultOperation.error {
                    self.errorAggregate.aggregate(error)
                }
            }
            
            if newOperations.count == 0 {
                self.operationObservation = nil
                
                if self.errorAggregate.hasErrors {
                    self.finish(withError: self.errorAggregate)
                } else {
                    self.finish()
                }
            }
        }
        
        queue.isSuspended = false
    }
    
    // MARK: Subclassing
    
    /**
     (Required) Override this method to add sub operations to the queue.
     */
    func operationQueueWillBeginExecution(queue: OperationQueue) {
        
    }
}
