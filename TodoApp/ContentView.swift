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
    var dateFormatter = DateFormatter()
    
    @Environment(\.colorScheme) var colorScheme
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileUrl = dir.appendingPathComponent("data.json")
            taskStore.setUrl(url: fileUrl)
            
            if FileManager.default.fileExists(atPath: fileUrl.path(percentEncoded: false)) {
                do {
                    let contents = try String(contentsOf: fileUrl, encoding: .utf8);
                    taskStore.load(jsonString: contents)
                } catch {
                    messageStore.message = "Could not load the file"
                }
            } else {
                print("File does not exist! \(fileUrl.absoluteString)")
            }
        }
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
                                Text("\(task.name)").frame(maxWidth: .infinity, alignment: .leading)
                            }.onTapGesture {
                                taskStore.remove(id: task.id)
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
                                Text("\(task.name)").frame(maxWidth: .infinity, alignment: .leading)
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
