//
//  DataStore.swift
//  TodoApp
//
//  Created by Ion Plamadeala on 06/06/2023.
//

import Foundation
import SwiftUI
import Combine

struct Task: Identifiable, Codable {
    var id = String()
    var name = String()
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
    
    public func add(task: String) {
        tasks.append(Task(id:UUID().uuidString.lowercased(), name: task))
        save()
    }
    
    public func remove(id: String) {
        if let index = tasks.firstIndex(where: {$0.id.elementsEqual(id)}) {
            let task = tasks[index]
            tasks.remove(at: index)
            finished.append(task)
            save()
        }
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
        return nil;
    }
    
    
    public func setUrl(url: URL) {
        self.url = url;
    }
    
    func clearFinished() {
        finished = []
        save()
    }
    
    public func save() {
        
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
    
}
