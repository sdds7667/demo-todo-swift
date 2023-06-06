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

enum TaskIndex {
    case number(index: Int)
    case prefix(index: String)
}

struct ActionResult {
    var command = String()
    var task = String()
    var focus: FocusedElement? = nil
    
    static func newTask() -> ActionResult {
        return ActionResult(
            focus: .newTask
        )
    }
}




class CommandHandler {
    func parse(command: String) -> Action {
        if command.elementsEqual("q"){
            exit(0)
        }
        if (command.elementsEqual("clear")) {
            return ClearFinishedTasks()
        }
        if (command.starts(with: "c\'")){
            let prefix = String(command.dropFirst(2))
            if (prefix.count != 3) {
                return ReportError(message: "Invalid id")
            }
            return CompleteTask(index: .prefix(index: prefix))
        } else if (command.starts(with: "c")){
            // command for complete a task
            let index = Int(command.dropFirst(1))
            if index == nil {
                return ReportError(message: "Failed to parse the index of the task")
            }
            return CompleteTask(index: .number(index: index!))
        }
        return ReportError(message: "Could not parse \(command)");
    }
}


protocol Action {
    
    func handle(taskStore: TaskDataStore, messageStore: MessageStore) -> ActionResult;
        
}

struct CompleteTask: Action {
    var index: TaskIndex;
    
    
    func handle(taskStore: TaskDataStore, messageStore: MessageStore) -> ActionResult {
        switch index {
        case let.number(index):
            return handleInt(taskStore: taskStore, messageStore: messageStore, index: index)
        case let.prefix(index):
            return handleString(taskStore: taskStore, messageStore: messageStore, prefix: index)
        }
    }
    
    func handleString(taskStore: TaskDataStore, messageStore: MessageStore, prefix: String) -> ActionResult {
        
        let taskId = taskStore.idFromPrefix(prefix: prefix);
        if (taskId == nil) {
            messageStore.showError(message: "Cannot complete task \(index). Out of bounds")
            return ActionResult(command: "c", focus: .command)
        } else {
            taskStore.remove(id: taskId!)
            return ActionResult.newTask()
        }
    }
    
    func handleInt(taskStore: TaskDataStore, messageStore: MessageStore, index: Int) -> ActionResult {
        let taskId = taskStore.idFromIndex(index: index-1);
        if (taskId == nil) {
            messageStore.showError(message: "Cannot complete task \(index). Out of bounds")
            return ActionResult(command: "c", focus: .command)
        } else {
            taskStore.remove(id: taskId!)
            return ActionResult.newTask()
        }
    }
    
    
}

struct ClearFinishedTasks: Action {
    func handle(taskStore: TaskDataStore, messageStore: MessageStore) -> ActionResult {
        taskStore.clearFinished()
        return ActionResult.newTask()
    }
}



struct ReportError: Action {
    var message = String()
    var command = String()
    
    func handle(taskStore: TaskDataStore, messageStore: MessageStore) -> ActionResult {
        messageStore.showError(message: message)
        return ActionResult(command: command, focus: .command)
    }
    
}
