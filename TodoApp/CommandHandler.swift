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
    
    static func commandWithPrefix(prefix: String) -> ActionResult {
        return ActionResult(
            command: prefix,
            focus: .command
        );
    }
}

func outOfBounds(taskIndex: TaskIndex) -> String {
    switch (taskIndex) {
    case let .number(index):
        return "Index \(index) is out of bounds.";
    case let .prefix(index):
        return "Index \(index) not found";
    }
}




class CommandHandler {
    
    private static func readId(chars: [Character], index: Int) -> (Int, TaskIndex)? {
        if let scalar = chars[index].unicodeScalars.first {
            if (CharacterSet.decimalDigits.contains(scalar)) {
                // digital index
                var ind = 0;
                for si in (index)..<chars.count {
                    if let digit = Int(String(chars[si])) {
                        ind = ind * 10 + digit
                    } else {
                        return (si, .number(index: ind))
                    }
                }
                return (chars.count, .number(index: ind))
            } else if (chars[index] == "'") {
                // string index
                if (index + 3) >= chars.count {
                    return nil
                }
                var result = ""
                for si in (index+1)...(index+3) {
                    result += String(chars[si])
                }
                return (index + 4, .prefix(index:result))
            }
        }
        return nil
    }
    
    func parse(command: String) -> Action {
        
        let chars = Array(command)
        
        
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
        } else if (command.starts(with: "p")) {
            if let (index, taskId) = readId(chars: chars, index: 1) {
                if (chars[index] == ",") {
                    
                    if let newPriority = Int(command.dropFirst(index+1)) {
                        return UpdatePriority(index:taskId, priority: newPriority)
                    } else {
                        return ReportError(message: "Failed to parse the new priority")
                    }
                    
                    
                } else {
                    return ReportError(message:"Malformed priority command")
                }
            }
            
        }
    
        
        
        return ReportError(message: "Could not parse \(command)");
    }
}


protocol Action {
    
    func handle(taskStore: TaskDataStore, messageStore: MessageStore) -> ActionResult;
        
}


struct UpdatePriority: Action {
    var index: TaskIndex;
    var priority: Int;
    
    func handle(taskStore: TaskDataStore, messageStore: MessageStore) -> ActionResult {
        if let task = taskStore.taskFromIndex(index: index) {
            task.priority = priority
            taskStore.sort()
            taskStore.save()
            return ActionResult.newTask()
        } else {
            messageStore.showError(message: outOfBounds(taskIndex: index))
            return ActionResult.commandWithPrefix(prefix: "p")
        }
    }
}

struct CompleteTask: Action {
    var index: TaskIndex;
    
    func handle(taskStore: TaskDataStore, messageStore: MessageStore) -> ActionResult {
        if let taskId = taskStore.idFromTaskIndex(index: index) {
            taskStore.remove(id: taskId)
            return ActionResult.newTask()
        } else {
            messageStore.showError(message: outOfBounds(taskIndex: index))
            return ActionResult.commandWithPrefix(prefix: "c");
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
