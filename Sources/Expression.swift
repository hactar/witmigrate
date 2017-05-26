//
//  Expression.swift
//  witmigrate
//
//  Created by patrick on 23/02/2017.
//  Copyright © 2017 patrick. All rights reserved.
//

import Foundation
import Unbox
struct Expression {
    var text: String
    var entities: [ExpressionEntity]?
    
    mutating func attach(intent: String) {
        if self.entities == nil {
            self.entities = []
        }
        self.entities!.append(ExpressionEntity(entity: "intent", wisp: nil, value: intent, role: nil, start: nil, end: nil))
    }
    
    func hash() -> String {
        if let entities = self.entities {
            let hashArray = entities.map { $0.hash() }
            let hashSorted = hashArray.sorted()
            return hashSorted.reduce("", +)
        } else {
            return "nullHash"
        }
    }
    
}

extension Expression: Unboxable {
    init(unboxer: Unboxer) throws {
        if let text: String = unboxer.unbox(key: "body") {
            self.text = text
        } else {
            self.text = try unboxer.unbox(key: "text")
        }
        self.entities = unboxer.unbox(key: "entities")
    }
}
