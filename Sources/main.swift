//
//  main.swift
//  witmigrate
//
//  Created by patrick on 22/02/2017.
//  Copyright © 2017 patrick. All rights reserved.
//

import Foundation
import Wrap
import Unbox


// actions
// app.json
// expressions
// stories
// entities ---
// intent
// location
// vienna_line
// viene_Station



func download(endpoint: String, parameters: String, apiKey: String, saveToPath: String) {
    
    let sema = DispatchSemaphore( value: 0)
    
    guard let myURL = URL(string: "https://api.wit.ai/\(endpoint)?v=20160526\(parameters)") else {exit(1)}
    var request = URLRequest(url: myURL)
    request.httpMethod = "GET"

    
    // Headers
    
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        print("after data is downloaded");
        if (error == nil) {
            // Success
            let statusCode = (response as! HTTPURLResponse).statusCode
            print("URL Session Task Succeeded: HTTP \(statusCode)")
            
            if let data = data {
                
                let fileUrl = URL.init(fileURLWithPath: saveToPath)
                        
                        //writing
                        do {
                            try data.write(to: fileUrl)
                            print("successfully saved \(saveToPath)")
                        }
                        catch {
                            print("could not save to \(saveToPath)")
                }
                        
                        //reading

                
            } else {
                print("Got back response with no data")
            }
            
        }
        else {
            // Failure
            print("URL Session Task Failed: %@", error!.localizedDescription);
        }
        sema.signal(); // signals the process to continue
    };
    
    task.resume();
    sema.wait();
    
}

func dataFor(path: String) -> Data? {
    do {
        let fileUrl = URL.init(fileURLWithPath: path)
        let cachedData = try Data.init(contentsOf: fileUrl)
        return cachedData
    } catch  {
        print("could not load cache...")
        return nil
    }
    
    
}

func legacyEntityNames(atPath: String) throws -> [String] {
    let data = dataFor(path: "\(atPath)/Entities/entities.json")
    return try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String]
}

func legacyIntentNames(atPath: String) throws -> [String] {
    if let data = dataFor(path: "\(atPath)/Intents/intents.json") {
        let jsonArray = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [[String:Any]]
        var intents: [String] = []
        for intent in jsonArray {
            intents.append(intent["name"] as! String)
        }
        return intents
    } else {
        throw NSError.init(domain: "filenotfoundIntentJSON", code: -1, userInfo: nil)
    }

}

func legacyItems<T: Unboxable>(names: [String], atPath: String) -> [T] {
    
    var tempEntities: [T] = []
    for name in names {
        print(name)
        if let data = dataFor(path: "\(atPath)/\(name).json") {
            do {
                let entity: T = try unbox(data: data)
                tempEntities.append(entity)
            } catch {
                print("Could not parse \(name).json")
                exit(1)
            }

        } else {
            print("Could not find \(name).json")
            exit(1)
        }
    }
    return tempEntities
}

func intentsAsEntity(from intents: [LegacyIntent]) -> Entity {
    var values: [ [String: String] ] = []
    for intent in intents {
        let valueDictionary = ["value": intent.name]
        values.append(valueDictionary)
        
    }
    return Entity(id: "123", name: "intent", lang: "de", lookups: ["trait"], exotic: false, values: values, doc: "generated from legacy intents", builtin: false)
    
}

func write(jsonObject: Any, toPath: String) throws {
    let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
    let string = String(data: data, encoding: .utf8)
    let stringFixed = string!.replacingOccurrences(of: "\\/", with: "/")
    let dataFixed = stringFixed.data(using: .utf8)
    let url = URL(fileURLWithPath: toPath)
    try dataFixed!.write(to: url)
}

func loadLegacyData(fromPath: String) throws -> (intents: [LegacyIntent], entities: [Entity]) {
    print("--- Loading legacy intents...")
    
    let names = try legacyIntentNames(atPath: fromPath)
    let intents: [LegacyIntent] = legacyItems(names: names, atPath: "\(fromPath)/Intents")
    
    print ("--- Loading legacy entities...");
    let entityNames = try legacyEntityNames(atPath: fromPath)
    let entities: [Entity] = legacyItems(names: entityNames, atPath: "\(fromPath)/Entities")
    
    return (intents: intents, entities: entities)
}


func upload(entity: String, data: Data, apiKey: String) {
    
    let sema = DispatchSemaphore( value: 0)
    
    guard let myURL = URL(string: "https://api.wit.ai/entities?v=20170307") else {exit(1)}
    var request = URLRequest(url: myURL)
    request.httpMethod = "POST"
    request.httpBody = data
    
    
    // Headers
    
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if (error == nil) {
            // Success
            let statusCode = (response as! HTTPURLResponse).statusCode
            print("\(entity) Task Succeeded: HTTP \(statusCode)")
            
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                print(json)
            } catch {
                print("could not unserialize");
            }
            //let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
             
            

        }
        else {
            // Failure
            print("\(entity) Task Failed: %@", error!.localizedDescription);
        }
        sema.signal(); // signals the process to continue
    };
    
    task.resume();
    sema.wait();
    
}

func uploadEntities(fromPath: String, apiKey: String) throws {
    
    let result = try loadLegacyData(fromPath: fromPath)
    var entities = result.entities
    let intents = result.intents
    let fixedIntents = addEntityNames(to: intents, with: entities)
    let intentEntity = intentsAsEntity(from: fixedIntents)
    entities.append(intentEntity)
    
    for entity in entities {
        if entity.builtin == false || entity.name == "location" || entity.name == "datetime" {
            var entityDictionary: [String:Any] = try wrap(entity)
            entityDictionary.removeValue(forKey: "name")
            entityDictionary.removeValue(forKey: "builtin")
            entityDictionary.removeValue(forKey: "exotic")
            entityDictionary.removeValue(forKey: "lookups")
            let data = try JSONSerialization.data(withJSONObject: entityDictionary, options: .prettyPrinted)
            print(String.init(data: data, encoding: .utf8)!)
            upload(entity: entity.name, data: data, apiKey: apiKey)
        }

    }
    
        
}


func generateOutput(fromPath: String) throws {
    

    let result = try loadLegacyData(fromPath: fromPath)
    let entities = result.entities
    let intents = result.intents
    
    
    print("-- Creating outputFolder...");
    let fixedIntents = addEntityNames(to: intents, with: entities)
    // create directory
    // create entities directory
    let url = URL(fileURLWithPath: "outputFolder")
    do {
        try FileManager.default.removeItem(at: url)
    } catch  {
        // folder probably did not exist, ignoring...
    }
    
    try FileManager.default.createDirectory(atPath: "outputFolder/entities", withIntermediateDirectories: true, attributes: nil)
    // copy over entities, removing wit$ from name (no can do sir, wisp instead of entity)
    
    for entity in entities {
        if entity.builtin == false || entity.name == "location" || entity.name == "datetime" {
            let entityDictionary: [String:Any] = try wrap(entity)
            let finalDictionary = ["data" : entityDictionary]
            try write(jsonObject: finalDictionary, toPath: "outputFolder/entities/\(entity.name).json")
        }

    }
    // create intent.json
    
    let intentEntity = intentsAsEntity(from: fixedIntents)
    let intentEntityDict: [String:Any] = try wrap(intentEntity)
    let intentEntityFinalDict = ["data": intentEntityDict]
    try write(jsonObject: intentEntityFinalDict, toPath: "outputFolder/entities/intent.json")
    
    // create app.json
    let app = ["version": 20160513, "zip-command" : "zip outputFolder.zip outputFolder/app.json outputFolder/entities/*.json outputFolder/actions.json outputFolder/stories.json outputFolder/expressions.json", "data" : ["name": "WaveStoryImport", "description" : "", "lang": "de"] ] as [String : Any]
    try write(jsonObject: app, toPath: "outputFolder/app.json")
    
    // create actions.json
    
    try FileManager.default.copyItem(atPath: "\(fromPath)/actions.json", toPath: "outputFolder/actions.json")
    // create expressions.json
    
    var expressionsFinal: [[String:Any]] = []
    var storyHashes: [String:Bool] = [:]
    var stories: [Story] = []
    
    
    let data = dataFor(path: "\(fromPath)/operations_stub.json")
    let operationsStub = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [[String: Any]]
    
    for fixedIntent in fixedIntents {
        for expression in fixedIntent.expressions {
            let expressionDictionary: [String: Any] = try wrap(expression)
            expressionsFinal.append(expressionDictionary)
            let hash = expression.hash()
            if storyHashes[hash] == nil {
                storyHashes[hash] = true
                let turn = Turn(user: expression.text, entities: expression.entities!, operations: operationsStub)
                let story = Story(name: "", turns: [ turn ])
                stories.append(story)
                
            } else {
               // print("already had \(hash)")
            }
        }
    }

    for key in storyHashes.keys {
        print(key)
    }
    
    //print(finalStoriesArray)
    let expressionsWrapper = ["data": expressionsFinal]
    try write(jsonObject: expressionsWrapper, toPath: "outputFolder/expressions.json")
    
    // create stories.json
    let storiesDictArray: [[String:Any]] = try wrap(stories)
    let finalStoriesDict = ["data": storiesDictArray]
    try write(jsonObject: finalStoriesDict, toPath: "outputFolder/stories.json")

}

func addEntityNames(to intents: [LegacyIntent], with entities: [Entity]) -> [LegacyIntent] {
    var lookupDictionary: [String: String] = [:]
    var returnIntents = intents
    for entity in entities {
        lookupDictionary[entity.id] = entity.name
    }
    for intentIndex in 0..<intents.count {
        for expressionIndex in 0..<intents[intentIndex].expressions.count {
            if intents[intentIndex].expressions[expressionIndex].entities != nil {
                for entityExpressionIndex in 0..<intents[intentIndex].expressions[expressionIndex].entities!.count {
                    if returnIntents[intentIndex].expressions[expressionIndex].entities![entityExpressionIndex].entity == nil {
                                            returnIntents[intentIndex].expressions[expressionIndex].entities![entityExpressionIndex].entity = lookupDictionary[intents[intentIndex].expressions[expressionIndex].entities![entityExpressionIndex].wisp!]
                    }

                }
            }

        }
    }
    return returnIntents
}

func outputExpressions(atPath: String) {
    
    if let data = dataFor(path: "\(atPath)/expressions.json") {
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            if var expressions = jsonDict["data"] as? [[String:Any]] {
                var cleanedExpressions: Set<String> = []
                for  (index,_) in expressions.enumerated() {
                    //print("\(expressions[index]["text"]!)")
                    let temp = expressions[index]["text"] as! String
                    let charsToRemove = CharacterSet.alphanumerics.inverted
                    let stripped = temp.components(separatedBy: charsToRemove).joined(separator: " ")
                    cleanedExpressions.insert(stripped)
                    
                }
                for woof in cleanedExpressions {
                    print(woof)
                }
            } else {
                print("Could not unserialize data in expressions.json file.")
            }
        } catch  {
            print("Could not unserialize expressions.json file.")
        }
        
        
    } else {
        print("Could not find expressions.json file.")
    }
    
}

func fixDownloadedExpressionsForSamplesAPI(atPath: String) {
    
    if let data = dataFor(path: "\(atPath)/expressions.json") {
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            if var expressions = jsonDict["data"] as? [[String:Any]] {
                for  (index,_) in expressions.enumerated() {
                    if let entities = expressions[index]["entities"] as? [[String:Any]] {
                        let fixedEntities = entities.map({ (entity) -> [String : Any] in
                            var mutableEntity = entity
                            let value = entity["value"] as! String
                            let startIndex = value.index(value.startIndex, offsetBy: 1)
                            let endIndex = value.index(value.endIndex, offsetBy: -2)
                            if entity["entity"] as! String == "location" {
                                mutableEntity["entity"] = "wit$location"
                            }
                            if entity["entity"] as! String == "datetime" {
                                mutableEntity["entity"] = "wit$datetime"
                            }
                            
                            
                            mutableEntity["value"] = value[startIndex...endIndex]
                            return mutableEntity
                        })
                        expressions[index]["entities"] = fixedEntities
                    }
                }
                try write(jsonObject: expressions, toPath: "\(atPath)/expressionsFixed.json")
            } else {
                print("Could not unserialize data in expressions.json file.")
            }
        } catch  {
            print("Could not unserialize expressions.json file.")
        }
       
        
    } else {
        print("Could not find expressions.json file.")
    }
    
}

func usageAndExit() {
    print("Usage: \nwitmigrate download <WITSERVERKEY> - downloads intents and entities from legacy wit api\nwitmigrate generate - generates files to import into wit story system\nwitmigrate fixexpressions - prints a cleaned up version of the expressions.json file")
    exit(1)
}

// main execution begins here

//outputExpressions(atPath: CommandLine.arguments[2])
//exit(1)

if CommandLine.arguments.count < 2 {
    usageAndExit()
}

switch CommandLine.arguments[1] {
  case "download":
    //download intents list
    //download(endpoint: "intents", parameters: "", saveToPath: "intents.json")
    // for every intent in the intents list
    // download the intent
    //download(endpoint: "intents/INTENTNAME", parameters: "", saveToPath: "Intents/INTENTNAME.json")
    
    // do the same for entities and place them in an Entities folder
    
    print("Download is not implemented yet, download all your intent jsons and place them into a Intents folder, do the same for entities and place them into an Entities folder")
    
    break
    case "generate":
    // fromPath needs to contain Intents and Entities folder, with json files downloaded from the wit.ai API.
    try generateOutput(fromPath: CommandLine.arguments[2])
    break
    case "fixexpressions":
    fixDownloadedExpressionsForSamplesAPI(atPath: CommandLine.arguments[2])
    break
    case "uploadentities":
    try uploadEntities(fromPath: CommandLine.arguments[2], apiKey: CommandLine.arguments[3])
    default:
        usageAndExit()
}

/*
 let app = App(version: "200612", zipCommand: "zip everything", data: ["name": "ConverseTest"])
 
 
 let dictionary: [String: Any] = try wrap(entity)
 print(dictionary)
 */
//download(endpoint: "intents", parameters: "", saveToPath: "intents.json")
//download(endpoint: "intents/get_route", parameters: "", saveToPath: "get_route.json")

/*
 
 */
//download(endpoint: "entities", parameters: "", saveToPath: "entities.json")


//print(fixedIntents)

//print(intentsAsEntity(from: try legacyIntents()))


//download intents list
// for every intent in the intents list
// download the intent
