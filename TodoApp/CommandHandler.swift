//
//  HandleCommand.swift
//  TodoApp
//
//  Created by Ion Plamadeala on 06/06/2023.
//

import Foundation

enum FocusedElement {
    case newTask
    case command
}

struct ActionResult {
    var command = String()
    var task = String()
    var focus: FocusedElement? = nil
}

class CommandHandler {
    func parse(command: String) -> Action {
        return ReportError(message: "Could not handle \(command)");
    }
}


protocol Action {
    
    func handle(taskStore: TaskDataStore, messageStore: MessageStore) -> ActionResult;
        
}

struct ReportError: Action {
    var message = String()
    var command = String()
    
    func handle(taskStore: TaskDataStore, messageStore: MessageStore) -> ActionResult {
        messageStore.showError(message: message)
        return ActionResult(command: command, focus: .command)
    }
    
}
