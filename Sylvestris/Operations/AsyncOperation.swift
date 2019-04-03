//
//  AsyncOperation.swift
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
 A subclass of Operation for performing asynchronious tasks.
 This class is intended to be subclassed, not used directly.
 */
class AsyncOperation: Operation, ResultOperation {
    enum State {
        case initialized
        case executing
        case finished
    }
    
    private var stateLock = NSLock()
    // Hidden state, has to be thread safe
    private var _state = State.initialized
    
    var state: State {
        get {
            stateLock.lock()
            
            let value = _state
            
            stateLock.unlock()

            return value
        }
        set(newState) {
            willChangeValue(forKey: "state")
            
            stateLock.lock()
            
            if _state != .finished {
                _state = newState
            }
            
            stateLock.unlock()
            
            didChangeValue(forKey: "state")
        }
    }
    var error: Error?
    
    // MARK: State overrides
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    // MARK: KVO setup
    
    @objc class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    @objc class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    @objc class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    // MARK: Running
    
    override func start() {
        assert(_state == .initialized)
        
        state = .executing
        
        if isCancelled {
            finishCancelled()
        }
        
        operationDidStart()
    }
    
    func finish(withError error: Error? = nil) {
        if self.error == nil {
            self.error = error
        }
        
        operationWillFinish()
        
        state = .finished
    }
    
    func finishCancelled() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        finish(withError: error)
    }
    
    // MARK: Subclassing
    
    /**
     (Required) Override this method to perform operation's objective.
     Use `finish()` or `finish(withError:)` to indicate that the task is complete.
     */
    func operationDidStart() {
        
    }
    
    /**
     (Optional) Called just before the operation completes.
     Can be used to notify other objects about completion and/or pass them results.
     */
    func operationWillFinish() {
        
    }
}
