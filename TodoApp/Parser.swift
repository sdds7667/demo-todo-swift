//
//  Parser.swift
//  TodoApp
//
//  Created by Ion Plamadeala on 09/06/2023.
//

import Foundation

enum Token : Equatable{
    case stringId(value: String)
    case number(value: Int)
    case string(value: String)
}

enum ParseErrors: Error {
    case unknown
    case wrongChar
    case malformedId
}

enum ParseState {
    case nothing
    case id(charsLeft: Int)
    case string
    case number
}


func parse(command: String) throws -> [Token] {
    
    let chars = Array(command)
    var tokenList = [Token]()
    var currentToken = ""
    var state : ParseState = .nothing
    
    var index = 0
    while index < command.count {
        let char = chars[index]
        index += 1
        
        switch (state) {
            case .nothing:
                if char == "'" {
                    state = .id(charsLeft: 3)
                } else if char.isNumber {
                    state = .number
                    currentToken.append(char)
                } else if char.isLetter {
                    state = .string
                    currentToken.append(char)
                } else {
                    tokenList.append(.string(value:String(char)))
                }
                
            
                
            case .number:
                if char.isNumber {
                    currentToken.append(char)
                    break
                } else {
                    tokenList.append(.number(value: Int(currentToken)!))
                    currentToken = ""
                    state = .nothing
                    index -= 1
                }
            case .id(let cl):
                if cl == 0 {
                    tokenList.append(.stringId(value: currentToken))
                    currentToken = ""
                    state = .nothing
                    index -= 1
                } else if (char.isNumber || char.isLetter) {
                    currentToken.append(char)
                    state = .id(charsLeft: cl - 1)
                } else {
                    throw ParseErrors.wrongChar
                }
            case .string:
                if char.isLetter {
                    currentToken.append(char)
                } else {
                    tokenList.append(.string(value: currentToken))
                    currentToken = ""
                    state = .nothing
                    index -= 1
                }
                
        }
    }
    
    switch state {
    case .id(let cl):
        if cl == 0 {
            tokenList.append(.stringId(value: currentToken))
        } else {
            throw ParseErrors.malformedId
        }
    case .number:
        tokenList.append(.number(value: Int(currentToken)!))
    case .string:
        tokenList.append(.string(value: currentToken))
    default:
        break
    }
    
    return tokenList
}
