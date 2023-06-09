//
//  DataStore.swift
//  TodoApp
//
//  Created by Ion Plamadeala on 06/06/2023.
//

import Foundation
import SwiftUI
import Combine

class Task: Identifiable, Codable {
    var id = String()
    var name = String()
    var created = Date()
    var priority = 3
    
    init(id: String = String(), name: String = String(), created: Date = Date(), priority: Int = 3) {
        self.id = id
        self.name = name
        self.created = created
        self.priority = priority
    }
}

class TaskDataStore: ObservableObject  {
    @Published var tasks = [Task]()
    @Published var finished = [Task]()
    private var url: URL? = nil
    private var encoder = JSONEncoder()
    
    
    public func load(jsonString : String) {
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode([[Task]].self, from: Data(jsonString.utf8));
            if decoded.count == 2 {
                tasks = decoded[0]
                finished = decoded[1]
            }
        } catch {
            
        }
    }
    
    public func add(task: String) -> Task{
        let newTask = Task(id:UUID().uuidString.lowercased(), name: task, created: .now)
        tasks.append(newTask)
        save()
        return newTask
    }
    
    public func sort() {
        tasks.sort { (lhs: Task, rhs: Task) -> Bool in
            return lhs.priority > rhs.priority
        }
    }
    
    public func complete(task: Task) {
        
        if let index = tasks.firstIndex(where: {$0.id.elementsEqual(task.id)}) {
            let task = tasks[index]
            tasks.remove(at: index)
            finished.append(task)
            save()
        }
    }
    
    public func remove(task: Task) -> Bool {
        
        if let index = tasks.firstIndex(where: {$0.id.elementsEqual(task.id)}) {
            tasks.remove(at: index)
            save()
            return true;
        } else if let index = finished.firstIndex(where: {$0.id.elementsEqual(task.id)}) {
            finished.remove(at: index)
            save()
            return true;
        }
        return false;
    }
    
    
    public func idFromIndex(index: Int) -> String? {
        if (index < 0 || index >= tasks.count) {
            return nil
        }
        return tasks[index].id
    }
    
    public func idFromPrefix(prefix: String) -> String? {
        for task in tasks {
            if (task.id.starts(with: prefix)) {
                return task.id
            }
        }
        
        for task in finished {
            if (task.id.starts(with: prefix)) {
                return task.id
            }
        }
        return nil;
    }
    
    public func idFromTaskIndex(index: TaskIndex) -> String? {
        switch index {
            case let .number(index):
                return idFromIndex(index: index-1)
            case let .prefix(index):
                return idFromPrefix(prefix: index)
        }
    }
    
    public func taskFromIndex(index: TaskIndex) -> Task? {
        if let id = idFromTaskIndex(index: index) {
            
            if let task = (tasks.first{task in task.id == id}) {
                return task
            } else {
                return finished.first{task in task.id == id}
            }
        } else {
            return nil
        }
    }
    
    
    public func setUrl(url: URL) {
        self.url = url;
    }
    
    func clearFinished() {
        finished = []
        save()
    }
    
    public func save() {
        sort()
        
        if url == nil {
            return
        }
        print("Saving to \(url!)")
        do {
            let res = try encoder.encode([tasks, finished]);
            do{
                try res.write(to: url!)
            } catch {
                print ("\(error)")
            }
        } catch {
            print("\(error)")
        }
        
    }
    
    private static func projectUrl(projectName: String) -> URL? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileUrl = dir.appendingPathComponent(projectName)
            return fileUrl
        }
        return nil
    }
    
    public func loadProject(projectName: String) -> Bool {
        save()
        if let newUrl = TaskDataStore.projectUrl(projectName: projectName) {
            self.setUrl(url: newUrl)
            print("\(newUrl)")
            do {
                let contents = try String(contentsOf: newUrl, encoding: .utf8);
                load(jsonString: contents)
                return true
            } catch {
                tasks = []
                finished = []
                return false
            }
        }
        return false
    }
}

class SettingsStore : Codable {
    public var defaultProject = "default.json"
    
    public func load() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileUrl = dir.appendingPathComponent(".settings.json")
            do {
                let contents = Data(try String(contentsOf: fileUrl, encoding: .utf8).utf8);
                let jdecoder = JSONDecoder()
                let res = try jdecoder.decode(SettingsStore.self, from: contents)
                self.defaultProject = res.defaultProject
            } catch  {
                let jencoder = JSONEncoder()
                do {
                    try jencoder.encode(self).write(to: fileUrl)
                } catch {
                    print("Couldn't write the settings file. ")
                }
            }
        }
    }
    
    private static func url(projectName: String) -> URL? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileUrl = dir.appendingPathComponent(projectName)
            return fileUrl
        }
        return nil
    }
    
}
