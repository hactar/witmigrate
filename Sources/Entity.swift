//
//  Entity.swift
//  witmigrate
//
//  Created by patrick on 23/02/2017.
//  Copyright © 2017 patrick. All rights reserved.
//

import Foundation
import Unbox
import Wrap

struct Entity {
    var id: String
    var name: String
    var lang: String?
    var lookups: [String]?
    var exotic: Bool?
    var values: [[String:Any]]?
    var doc: String
    var builtin: Bool?
    
}


extension Entity: Unboxable, WrapCustomizable {
    init(unboxer: Unboxer) throws {
        self.name = try unboxer.unbox(key: "name")
        self.id = try unboxer.unbox(key: "id")
        self.doc = try unboxer.unbox(key: "doc")
        self.lang =  unboxer.unbox(key: "lang")
        self.lookups = unboxer.unbox(key: "lookups")
        self.exotic = unboxer.unbox(key: "exotic")
        self.values =  unboxer.unbox(key: "values")
        self.builtin =  unboxer.unbox(key: "builtin")
        if self.values != nil {
            for index in 0..<self.values!.count {
                var tempArray = self.values![index]["expressions"] as! [String]
                if tempArray.contains(self.values![index]["value"] as! String) == false {
                    tempArray.append(self.values![index]["value"] as! String)
                    self.values![index]["expressions"]  = tempArray
                }

            }
        }

    }
    
    func wrap(propertyNamed propertyName: String, originalValue: Any, context: Any?, dateFormatter: DateFormatter?) throws -> Any? {
        
        if propertyName == "id" { // new wit system likes to have id be the name of entity too
            return self.name
        }
        return nil
        
    }
    
    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        if propertyName == "values" && self.builtin == true {
            return nil
        }
        return propertyName
    }
}
