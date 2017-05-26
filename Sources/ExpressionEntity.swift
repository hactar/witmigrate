//
//  ExpressionEntity.swift
//  witmigrate
//
//  Created by patrick on 23/02/2017.
//  Copyright © 2017 patrick. All rights reserved.
//

import Foundation
import Unbox
import Wrap


struct ExpressionEntity {
    var entity: String?
    var wisp: String?
    var value: String
    var role: String?
    var start: Int?
    var end: Int?
    
    func hash() -> String {
        if self.entity == "intent" {
            return self.value
        }
        let rolestr: String
        if role != nil {
            rolestr = ":\(role!)"
        } else {
            rolestr = ""
        }
        return "\(entity!)\(rolestr)"
    }
    
}

extension ExpressionEntity: Unboxable, WrapCustomizable  {
    init(unboxer: Unboxer) throws {
        self.entity = unboxer.unbox(key: "entity")
        self.wisp = unboxer.unbox(key: "wisp")
        self.value = try unboxer.unbox(key: "value")
        self.role = unboxer.unbox(key: "role")
        self.start = unboxer.unbox(key: "start")
        self.end = unboxer.unbox(key: "end")
    }
    
    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        if propertyName == "wisp" {
            return nil
        }
        return propertyName
    }
    
    func wrap(propertyNamed propertyName: String, originalValue: Any, context: Any?, dateFormatter: DateFormatter?) throws -> Any? {
        if propertyName == "value" {
            return "\"\(self.value)\""
        }
        return nil
    }
}
