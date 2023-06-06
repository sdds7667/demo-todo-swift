//
//  ContentView.swift
//  TodoApp
//
//  Created by Ion Plamadeala on 06/06/2023.
//


import SwiftUI


struct ContentView: View {
    @FocusState private var focus: FocusedElement?;
    
    @ObservedObject var taskStore = TaskDataStore()
    @ObservedObject var messageStore = MessageStore()
    
    @State var newTask : String = ""
    @State var command: String = "";
    @State var commandInFocus: Bool = false;
    var timer : Timer? = nil;
    var commandHandler = CommandHandler()
    let font = Font.system(.body, design: .monospaced)
    var addTaskBar : some View {
        HStack {
            TextField ("Add Task: ", text: self.$newTask).font(font).onSubmit {
                addNewTask()
            }.focused($focus, equals: .newTask)
                .onChange(of: newTask, perform: {newValue in
                    if (newValue == ":") {
                        newTask = "";
                        commandInFocus = true;
                        command = ""
                        focus = .command
                    }
                })
            Button(action: self.addNewTask, label: {
                Text("Add New").font(font)
            })
        }
    }
    
    var tasks = ["Task 1", "Task 2", "Task 3"];
    var body: some View {
            VStack {
                addTaskBar
                List {
                    ForEach(taskStore.tasks) { task in
                        Text(task.name).onTapGesture {
                            taskStore.remove(id: task.id)
                        }.font(font)
                    }
                }
                List {
                    ForEach(taskStore.finished) {
                        Text($0.name).strikethrough().font(font)
                    }
                }
                if (!messageStore.message.isEmpty) {
                    Text(messageStore.message).bold().foregroundColor(.red).font(font).frame(maxWidth: .infinity, alignment: .leading)
                   
                }
                if (commandInFocus) {
                    TextField("Command: ", text: $command).focused($focus, equals:.command)
                        .onSubmit {
                            handleCommand()
                        }.font(font).onChange(of: command) {newCommand in
                            if (newCommand.elementsEqual("q")) {
                                setFocus(newFocus: .newTask)
                            }
                        }
                }
                
            }
            .padding()
    }
    
    func setFocus(newFocus: FocusedElement?) {
        focus = newFocus
        commandInFocus = newFocus == .command
    }
    
    func handleCommand(){
        let actionRunResult = commandHandler.parse(command: command).handle(taskStore: taskStore, messageStore: messageStore)
        command = actionRunResult.command
        newTask = actionRunResult.task
        setFocus(newFocus: actionRunResult.focus)
    }
    
    
    func addNewTask() {
        self.taskStore.add(task: newTask)
        newTask = "";
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
