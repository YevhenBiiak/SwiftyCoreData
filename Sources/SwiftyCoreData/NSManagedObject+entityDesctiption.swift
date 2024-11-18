//
//  NSManagedObject+entityDesctiption.swift
//  SwiftyCoreData
//
//  Created by Yevhen Biiak on 18.11.2024.
//

import CoreData


extension NSManagedObject {
    
    static var entityDescription: NSEntityDescription {
        
        let properties = getPropertyNamesAndTypes(for: Self.self).map { p in
            let attr = NSAttributeDescription()
            attr.name = p.name
            attr.attributeType = p.type
            attr.valueTransformerName = p.transformer
            return attr
        }
        
        let entity = NSEntityDescription()
        entity.properties = properties
        entity.name = String(describing: Self.self)
        entity.managedObjectClassName = NSStringFromClass(Self.self)
        
        return entity
    }
    
    static func getPropertyNamesAndTypes(for type: AnyClass) -> [(name: String, type: NSAttributeType, transformer: String?)] {
        
        var count: UInt32 = 0
        let properties = class_copyPropertyList(type, &count)
        var results: [(String, NSAttributeType,String?)] = []
        
        for i in 0..<Int(count) {
            if let property = properties?[i],
               let name = NSString(utf8String: property_getName(property)) as String?,
               let attributes = property_getAttributes(property),
               let attributesString = NSString(utf8String: attributes) as String?,
               let typeAttribute = attributesString.split(separator: ",").first
            {
                // print(attributesString)
                let typeCode = typeAttribute.replacingOccurrences(of: "T", with: "")
                let type = typeDescription(for: typeCode)
                let transformer = type == .transformableAttributeType ? NSStringFromClass(ArrayTransformer.self) : nil
                results.append((name, type, transformer))
            }
        }
        
        free(properties)
        
        return results
        
        func typeDescription(for typeCode: String) -> NSAttributeType {
            switch typeCode {
            case "i": // "Int32"
                return .integer32AttributeType
            case "s": // "Int16"
                return .integer16AttributeType
            case "q": // "Int64"
                return .integer64AttributeType
            case "f": // "Float"
                return .floatAttributeType
            case "d": // "Double"
                return .doubleAttributeType
            case "B": // "Bool"
                return .booleanAttributeType
                
            case "@\"NSString\"", "String": // "NSString"
                return .stringAttributeType
                
            case "@\"NSUUID\"", "UUID": // "NSUUID"
                return .UUIDAttributeType
                
            case "@\"NSDate\"", "Date": // "NSDate"
                return .dateAttributeType
                
            case "@\"NSData\"", "Data": // "NSData"
                return .binaryDataAttributeType
                
            case "@\"NSURL\"", "URL": // "NSURL"
                return .URIAttributeType
                
            default:
                return .transformableAttributeType
            }
        }
    }
}
