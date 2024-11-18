//
//  ArrayTransformer.swift
//  SwiftyCoreData
//
//  Created by Yevhen Biiak on 18.11.2024.
//

import Foundation


@objc(ArrayTransformer)
class ArrayTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let array = value as? [Any] else { return nil }
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: false)
        } catch {
            print("Failed to encode array of Data: \(error)")
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
        } catch {
            print("Failed to decode array of Data: \(error)")
            return nil
        }
    }
}
