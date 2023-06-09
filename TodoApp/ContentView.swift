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
    @ObservedObject var commandHandler = CommandHandler()
    
    @State var newTask : String = ""
    @State var command: String = "";
    @State var commandInFocus: Bool = false;
    @State var editNewName: String = ""
    var timer : Timer? = nil;
    let font = Font.system(.body, design: .monospaced)
    var dateFormatter = DateFormatter()
    
    @Environment(\.colorScheme) var colorScheme
    
    init() {
        
        let settings = SettingsStore()
        settings.load()
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        _ = taskStore.loadProject(projectName: settings.defaultProject)
    }
    
    
    
    var body: some View {
            VStack {
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
                ScrollView(.vertical) {
                    LazyVGrid(columns: [
                        GridItem(.fixed(30)),
                        GridItem(.fixed(130)),
                        GridItem(.fixed(15)),
                        GridItem(.adaptive(minimum: 500, maximum: .infinity))
                        
                    ]){
                        ForEach(taskStore.tasks) { task in
                            
                            let id = String(task.id.dropLast(33)).lowercased()
                            let date = dateFormatter.string(from: task.created)
                            
                            GridRow {
                                Text("\(id)").foregroundColor(.secondary).font(font)
                                Text("\(date)").font(font).foregroundColor(.secondary)
                                Text("\(task.priority)").font(font).foregroundColor(.secondary)
                                if (commandHandler.selectedTaskId != nil && id.elementsEqual(commandHandler.selectedTaskId!)) {
                                    if (commandHandler.nameEditor) {
                                        TextField("New Task Name", text:self.$editNewName).font(font).focused($focus, equals:.tableEditor)
                                            .onSubmit {
                                                self.editTaskName(task:task)
                                                self.editNewName = ""
                                                self.commandHandler.nameEditor = false
                                                self.focus = .newTask
                                                taskStore.save()
                                            }.onExitCommand {
                                            commandHandler.nameEditor = false
                                            self.editNewName = ""
                                        }
                                    } else {
                                        Text("\(task.name)").frame(maxWidth: .infinity, alignment: .leading).foregroundColor(Color.accentColor)
                                    }

                                }else {
                                    Text("\(task.name)").frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }.onTapGesture {
                                _ = taskStore.remove(task: task)
                            }
                                
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300, alignment: .topLeading)
                }.frame(maxHeight: 200).background(.background)
                ScrollView(.vertical) {
                    LazyVGrid(columns: [
                        GridItem(.fixed(35)),
                        GridItem(.fixed(130)),
                        GridItem(.fixed(15)),
                        GridItem(.adaptive(minimum: 500, maximum: .infinity))
                    ]){
                        ForEach(taskStore.finished) { task in
                            let date = dateFormatter.string(from: task.created)
                            let id = String(task.id.dropLast(33)).lowercased()
                            GridRow {
                                Text("\(id)").foregroundColor(.secondary).font(font)
                                Text("\(date)").font(font).foregroundColor(.secondary)
                                Text("\(task.priority)").font(font).foregroundColor(.secondary)
                                if (commandHandler.selectedTaskId != nil && id.elementsEqual(commandHandler.selectedTaskId!)) {
                                    Text("\(task.name)").frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(.accentColor)
                                } else {
                                    Text("\(task.name)").frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }.strikethrough()
                        }
                    }.frame(maxWidth: .infinity, maxHeight: 300, alignment: .topLeading)
                }.frame(maxHeight: 300).background(.background)
                if (!messageStore.message.isEmpty) {
                    Text(messageStore.message).bold().foregroundColor(.accentColor).font(font).frame(maxWidth: .infinity, alignment: .leading)
                   
                }
                if (commandInFocus) {
                    TextField("Command: ", text: $command).focused($focus, equals:.command)
                        .onSubmit {
                            handleCommand()
                        }.font(font).onChange(of: command) {newCommand in
                            if (newCommand.elementsEqual(" ")) {
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
//        print("Focus changed. \(newFocus) -> \(focus) ")
//        print("Command in focus: . \(commandInFocus)")
    }
    
    
    func editTaskName(task: Task) {
        task.name = self.editNewName
        
    }
    
    func handleCommand(){
        let actionRunResult = commandHandler.parse(command: command).handle(taskStore, messageStore, commandHandler)
        command = actionRunResult.command
        newTask = actionRunResult.task
        if let editString = actionRunResult.editNewName {
            editNewName = editString
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            setFocus(newFocus: actionRunResult.focus)
        }
    }
    
    
    func addNewTask() {
        let task = self.taskStore.add(task: newTask)
        self.commandHandler.selectedTaskId = String(task.id.dropLast(33));
        newTask = "";
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
