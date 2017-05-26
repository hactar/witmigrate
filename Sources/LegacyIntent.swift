//
//  LegacyIntent.swift
//  witmigrate
//
//  Created by patrick on 25/02/2017.
//
//

import Foundation
import Unbox


struct LegacyIntent {
    let id: String
    let name: String
    let doc: String
    var expressions: [Expression]
}

extension LegacyIntent: Unboxable {
    init(unboxer: Unboxer) throws {
        self.name = try unboxer.unbox(key: "name")
        self.id = try unboxer.unbox(key: "id")
        self.doc = try unboxer.unbox(key: "doc")
        self.expressions = try unboxer.unbox(key: "expressions")
        for index in 0..<self.expressions.count {
            self.expressions[index].attach(intent: self.name)
        }
        
    }
}
