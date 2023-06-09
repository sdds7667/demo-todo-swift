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
    case tableEditor
}

enum TaskIndex {
    case number(index: Int)
    case prefix(index: String)
}

struct ActionResult {
    var command = String()
    var task = String()
    var editNewName: String? = nil
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



class CommandHandler: ObservableObject {
    @Published var selectedTaskId: String? = nil
    @Published var nameEditor: Bool = false
    
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
        } else if (command.elementsEqual("e")) {
            return EditName();
        } else if (command.elementsEqual("d")) {
            return DeleteCommand()
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
                return CompleteTask(index: nil)
            }
            return CompleteTask(index: .number(index: index!))
        } else if (command.starts(with: "p")) {
            if let (index, taskId) = CommandHandler.readId(chars: chars, index: 1) {
                
                if index == chars.count { // command format: p[number] -- change the priority of selected element to the new number.
                    if case .number(let index) = taskId {
                        return UpdatePriority(taskIndex: nil, priority: index)
                    } else {
                        return ReportError(message: "Malformed priority command")
                    }
                } else if (chars[index] == ",") {
                    
                    if let newPriority = Int(command.dropFirst(index+1)) {
                        return UpdatePriority(taskIndex:taskId, priority: newPriority)
                    } else {
                        return ReportError(message: "Failed to parse the new priority")
                    }
                } else {
                    return ReportError(message:"Malformed priority command")
                }
            } else {
                if let newPriority = Int(command.dropFirst(1)) {
                    return UpdatePriority(taskIndex: nil, priority: newPriority)
                }
            }
            
        } else if (command.starts(with: "'")) {
            if let (index, taskId) = CommandHandler.readId(chars: chars, index: 0) {
                if (index == chars.count) {
                    if case .prefix(let id) = taskId {
                        return SelectTask(taskId: id)
                    }
                }
            }
        } else if (command.starts(with: "d")) {
            if let (index, taskId) = CommandHandler.readId(chars: chars, index: 0) {
                if (index == chars.count) {
                    return DeleteCommand(index:taskId)
                }
            }
        } else if (command.starts(with: "load ")) {
            return LoadProject(projectName: String(command.dropFirst(5)))
            
        }
        return ReportError(message: "Could not parse \(command)");
    }
}


protocol Action {
    
    func handle(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler) -> ActionResult;
        
}


class TaskIndexedAction: Action {
    var index: TaskIndex?
    var failPrefix: String = ""
    
    init(index: TaskIndex? = nil, failPrefix: String) {
        self.index = index
        self.failPrefix = failPrefix
    }
    
    func handle(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler) -> ActionResult {
        if index == nil && commandHandler.selectedTaskId == nil {
            messageStore.showError(message: messageNoIndex())
            return ActionResult.commandWithPrefix(prefix: failPrefix)
        }
        if index == nil {
            return handleWithTaskIndex(taskStore, messageStore, commandHandler, .prefix(index: commandHandler.selectedTaskId!))
        }
        return handleWithTaskIndex(taskStore, messageStore, commandHandler, index!)
    }
    
    func handleWithTaskIndex(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler, _ taskIndex: TaskIndex) -> ActionResult {
        
        if let task = taskStore.taskFromIndex(index: taskIndex) {
            return self.handleCheckedIndex(taskStore, messageStore, commandHandler, taskIndex, task)
        } else {
            messageStore.showError(message: outOfBounds(taskIndex: taskIndex))
            return ActionResult.commandWithPrefix(prefix: self.failPrefix)
        }
    }
    
    func handleCheckedIndex(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler, _ taskIndex: TaskIndex, _ task: Task) -> ActionResult {
        messageStore.showError(message: "Action not yet implemented")
        return ActionResult.newTask()
    }
    
    func messageNoIndex() -> String {
        return "This action requires a target task. It wasn't provided nor selected";
    }
    
}

class EditName: Action {
    func handle(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler) -> ActionResult {
        if (commandHandler.selectedTaskId != nil) {
            if let task = taskStore.taskFromIndex(index: .prefix(index: commandHandler.selectedTaskId!)) {
                    commandHandler.nameEditor = true;
                    return ActionResult(command:"", task:"", editNewName: task.name, focus: .tableEditor)
                }
            }
        messageStore.showError(message: "No object selected to edit")
        return ActionResult.commandWithPrefix(prefix: "")
    }
    
}


class UpdatePriority: TaskIndexedAction {
    var priority: Int;
    
    init(taskIndex: TaskIndex?, priority: Int) {
        self.priority = priority
        super.init(index: taskIndex, failPrefix: "p")
    }
    
    override func handleCheckedIndex(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler, _ taskIndex: TaskIndex, _ task: Task) -> ActionResult {
        task.priority = self.priority
        taskStore.sort()
        taskStore.save()
        return ActionResult.newTask()
    }
}

class LoadProject : Action{
    var projectName: String
    
    init(projectName: String) {
        self.projectName = projectName
    }
    
    func handle(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler) -> ActionResult {
        _ = taskStore.loadProject(projectName: projectName)
        return ActionResult.newTask()
    }
}

struct SelectTask: Action {
    var taskId: String
    func handle(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler) -> ActionResult {
        if let _ = taskStore.idFromPrefix(prefix: taskId) {
            commandHandler.selectedTaskId = taskId;
            return ActionResult.commandWithPrefix(prefix: "")
        } else {
            messageStore.showError(message: "Cannot find \(taskId)")
            return ActionResult.commandWithPrefix(prefix: "'")
        }
    }
}

class CompleteTask: TaskIndexedAction {
    
    init(index: TaskIndex? = nil) {
        super.init(index: index, failPrefix: "c")
    }
    
    override func handleCheckedIndex(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler, _ taskIndex: TaskIndex, _ task: Task) -> ActionResult {
        taskStore.complete(task: task)
        return ActionResult.newTask()
    }
}

struct ClearFinishedTasks: Action {
    func handle(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler) -> ActionResult {
        taskStore.clearFinished()
        return ActionResult.newTask()
    }
}

class DeleteCommand: TaskIndexedAction {
    init(index: TaskIndex? = nil) {
        super.init(index: index, failPrefix: "c")
    }
    override func handleCheckedIndex(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler, _ taskIndex: TaskIndex, _ task: Task) -> ActionResult {
        _ = taskStore.remove(task: task)
        commandHandler.selectedTaskId = nil
        return ActionResult.newTask()
    }
    
}



struct ReportError: Action {
    var message = String()
    var command = String()
    
    func handle(_ taskStore: TaskDataStore, _ messageStore: MessageStore, _ commandHandler: CommandHandler) -> ActionResult {
        messageStore.showError(message: message)
        return ActionResult(command: command, focus: .command)
    }
    
}
