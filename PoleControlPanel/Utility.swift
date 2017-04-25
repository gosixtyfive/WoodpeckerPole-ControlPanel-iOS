//
//  Utility.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/7/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import UIKit
import Foundation

/// Enum for handliing responses from Async and Sync requests
///
/// - success: Associated data wraps successful result
/// - failure: Associated data wraps failure Error
public enum Result<T> {
    ///
    case success(T)
    ///
    case failure(Error)
}

public extension Result {
    func map<U>(_ f: (T)->U) -> Result<U> {
        switch self {
        case .success(let t):  return .success(f(t))
        case .failure(let err):  return .failure(err)
        }
    }
    func flatMap<U>(_ f: (T)->Result<U>) -> Result<U> {
        switch self {
        case .success(let t):  return f(t)
        case .failure(let err):  return .failure(err)
        }
    }
}

public extension Result {
    func resolve() throws -> T {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
    init(_ throwingExpr: (Void) throws -> T) {
        do {
            let value = try throwingExpr()
            self = Result.success(value)
        } catch {
            self = Result.failure(error)
        }
    }
}


public struct Queue<T> {
    private var array = [T]()
    
    public var count: Int {
        return array.count
    }
    
    public var isEmpty: Bool {
        return array.isEmpty
    }
    
    public mutating func enqueue(_ element: T) {
        array.append(element)
    }
    
    public mutating func dequeue() -> T? {
        if isEmpty {
            return nil
        } else {
            return array.removeFirst()
        }
    }
    
    public mutating func flush() {
        array.removeAll()
    }
    
    public var front: T? {
        return array.first
    }
}

extension UIFont {
    
    class func boldSystemFontWithMonospacedNumbers(size: CGFloat) -> UIFont {
        let features = [
            [
                UIFontFeatureTypeIdentifierKey: kNumberSpacingType,
                UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector
            ]
        ]
        
        let fontDescriptor = UIFont.boldSystemFont(ofSize: size).fontDescriptor.addingAttributes(
            [UIFontDescriptorFeatureSettingsAttribute: features]
        )
        
        return UIFont(descriptor: fontDescriptor, size: size)
    }
    
    class func systemFontWithMonospacedNumbers(size: CGFloat) -> UIFont {
        let features = [
            [
                UIFontFeatureTypeIdentifierKey: kNumberSpacingType,
                UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector
            ]
        ]
        
        let fontDescriptor = UIFont.systemFont(ofSize: size).fontDescriptor.addingAttributes(
            [UIFontDescriptorFeatureSettingsAttribute: features]
        )
        
        return UIFont(descriptor: fontDescriptor, size: size)
    }

    
}



